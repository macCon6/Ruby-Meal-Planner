# Mackenzie Conway
# Creates a nightly dinner plan for each day of the week given meal/side/dessert options, a budget, and dietary restrictions.

class DinnerPlanner
  # @@ means class variable 
  @@weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

  def initialize(bdgt, sweet_tooth, rstrct=nil)
    @budget, @sweet_tooth, @restrictions = bdgt, sweet_tooth, rstrct 
    @current_cost = 0
    @side_cost = 3 # Each side dish costs $6
    @dessert_cost = 6 # Each dessert dish costs $3
    @side_cost, @dessert_cost = @dessert_cost, @side_cost # Now the costs are correct! 

    # Showing the use of a dynamic variable assignment (instance_variable_set)
    instance_variable_set("@sweets_count", 0) if sweet_tooth  # Only create sweets_count instance var if sweet_tooth is true
  end


  # Returns a hash with the days of the week as keys
  # Values are arrays of info about the day's plan (main, side, dessert, cost)
  # Example: {"Monday": [:spaghetti, :garlic_bread, :ice_cream, 19], "Tuesday": [:burgers, :french_fries, :cake, 30]}
  def auto_plan_dinners(meals, side, dessert)
    plan = Hash.new
    attempts = 1
    while(plan.count < 7) # Must have a plan for all weekdays
      @@weekdays.each do |day|
        todays_meal = single_meal(meals, side, dessert)
        if todays_meal
          plan[day] = todays_meal
        else # single_meal returned nil; no meals fit the remaining budget/restrictions
          attempts += 1
          if attempts > 50
              return puts "\nCouldn't make a plan after #{attempts} attempts, try increasing budget :("
          end
          plan.clear
          @current_cost = 0
          break # retries the loop since plan.count is now 0
        end
      end
    end
    yield
    puts "(This plan took #{attempts} attempts)"
    puts "Here is your weekly dinner plan for a $#{@budget} budget!\n"
    print_plan(plan)
  end

 
  # Returns a hash containing all of the meals whose cost fits the remaining budget
  def find_valid_meals(meals)
    available_meals = Hash.new
    meals.each do |key, value|
      cost = value.is_a?(Integer) ? value : value[0] # meals value is either just the cost integer or a list with cost as first element
      if(cost + @current_cost) <= @budget
        # add the exact hash entry from meals to the available_meals hash
        available_meals[key] = value
      end
    end
      available_meals # Ruby methods return their last statement
  end


  # Returns an array of all components of one day's plan ; nil if no meals fit remaining budget
  # Example: [:steak, :french_fries, :ice_cream, 29]
  def single_meal(meals, side, dessert)
    dinner = nil
    while(!dinner)
      available_meals = find_valid_meals(meals)
      if available_meals.empty?
        return nil
      end
      # Picks a random meal from hash & puts all information into an array
      choice =  available_meals.to_a.sample # Example: choice = [:tofu, [5, "vegetarian"]] or choice = [:spaghetti, 10]

      cost = choice.find { |cost| cost.is_a?(Integer)} 
      # If cost was not assigned, that means the cost is in a nested array
      cost ||= choice[1][0] 
     
      if !@restrictions
        dinner = choice[0]  
      elsif choice[1].is_a?(Array) && choice[1].include?(@restrictions)
          dinner = choice[0]
      end
    end
    @current_cost += cost

    # take_out doesn't need sides
    day_plan = [dinner, (pick_side(side) if dinner != :take_out)]

    # All plans with a sweet tooth must have dessert every night; randomly assign it to others
    if (defined?(@sweets_count) && @sweets_count < 7) || (rand(2) == 1)
      day_plan << pick_dessert(dessert)
    end
    cost += @side_cost if day_plan[1] # Side & dessert always at index 1 and 2
    cost += @dessert_cost if day_plan[2]
    day_plan << cost # Total cost for this day
    day_plan 
  end


  # dynamically creates pick_side and pick_dessert methods
  # returns a side or dessert symbol if it fits the budget, otherwise nil
  %w(side dessert).each do |component|
    define_method("pick_#{component}") do |options|
      component_cost = instance_variable_get("@#{component}_cost") # gets side_cost or dessert_cost
      if(@current_cost + component_cost) <= @budget
        @current_cost += component_cost
        options.sample # a random entry from the desserts or sides array
      else
        nil
      end
    end
  end

  def print_plan(plan)
    total_cost = 0
    plan.each do |key, value|
      cost = value.last
      total_cost += cost
      puts "#{key} ($#{cost}): #{(value[0...-1].compact).join(", ")}" # compact removes nil values
    end
    puts "Total cost: $#{total_cost}"
  end
end

meals = {spaghetti: 10, steak: 20, tofu: [5, "vegetarian"], burgers: [12], lentil_soup: [7, "vegetarian"], grilled_chicken: [9], take_out: [30, "vegetarian"], 
         veggie_burgers: [9, "vegetarian"], meatless_chili: [8, "vegetarian"]}
side = [:french_fries, :garlic_bread, :roasted_potatoes, :green_beans, :chips, :corn, :broccoli]
dessert = [:ice_cream, :cake, :cookies, :frozen_yogurt, :chocolate]

plan1 = DinnerPlanner.new(200, true) # Weekly budget of $200, no restrictions (uses default nil)
plan2 = DinnerPlanner.new(125, false, "vegetarian") # Weekly budget of $125, vegetarian meals only
plan3 = DinnerPlanner.new(300, true, "vegetarian") 
plan4 = DinnerPlanner.new(90, false) 

plan1.auto_plan_dinners(meals, side, dessert) { print "\nThis is the first plan! "}
plan2.auto_plan_dinners(meals, side, dessert) { print "\nThis is the second plan! "}
plan3.auto_plan_dinners(meals, side, dessert) { print "\nThis is the third plan! "}
plan4.auto_plan_dinners(meals, side, dessert) { print "\nThis is the last plan! "}