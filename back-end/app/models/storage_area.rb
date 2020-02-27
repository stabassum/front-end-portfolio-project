require 'pry'

class StorageArea < ApplicationRecord
  has_many :pallets

  def total_pallet_weight
    total_weight = []
    self.pallets.each do |pallet|
      total_weight << pallet.weight
    end
    total_weight.sum
  end

  def total_pallets
    self.pallets.count
  end

  def total_pallet_order # StorageArea.all[0].total_pallet_order
    self.pallets.sort_by(&:weight)
  end

  # do division & round to the closest integer
  def round_div(x,y)
    (x + y / 2) / y
  end

  def calculate_weight_for_1_pallet # StorageArea.all[0].calculate_weight_for_1_pallet
    self.pallets.each do |pallet|
      pallet.weight_category = "green"
      pallet.save
    end
  end

  def calculate_weight_for_2_pallets
    total_pallet_order.first.weight_category = "green"
    total_pallet_order.second.weight_category = "amber"
    total_pallet_order.each{|pallet| pallet.save}
  end

  def calculate_weight_for_3_pallets # StorageArea.all[0].calculate_weight_for_3_pallets
    total_pallet_order.first.weight_category = "green"
    total_pallet_order.second.weight_category = "amber"
    total_pallet_order.last.weight_category = "red"
    total_pallet_order.each{|pallet| pallet.save}
  end

  def calculate_weight_for_3_plus_pallets # StorageArea.all[0].calculate_weight_for_3_plus_pallets
    mean_average = total_pallet_weight / total_pallets # my_var_1

    pallets_below_mean_average = self.pallets.where("weight <= ?", mean_average)

    one_third_of_pallets = round_div(total_pallets, 3) # my_var_3
    half_of_that_one_third = round_div(one_third_of_pallets, 2) # my_var_4

    lower_value_amber_pallets = self.pallets.order(weight: :desc).where("weight <= ?", mean_average).limit(half_of_that_one_third) # my_var_5
    higher_value_amber_pallets = self.pallets.order(weight: :asc).where("weight >= ?", mean_average).limit(half_of_that_one_third) # my_var_6
    green_pallets = self.pallets.where("weight < ?", lower_value_amber_pallets.last.weight).sort_by(&:weight) # my_var_7
    red_pallets = self.pallets.where("weight > ?", higher_value_amber_pallets.last.weight).sort_by(&:weight) # my_var_8

    def assign_weight_categories(pallet_set, color_value)
      pallet_set.each do |pallet|
        pallet.weight_category = color_value
        pallet.save
      end
    end

    assign_weight_categories(lower_value_amber_pallets, "amber")
    assign_weight_categories(higher_value_amber_pallets, "amber")
    assign_weight_categories(green_pallets, "green")
    assign_weight_categories(red_pallets, "red")
  end

  def duplicate_pallet_weight_values_have_same_weight_category # StorageArea.all[1].duplicate_pallet_weight_values_have_same_weight_category
    total_pallet_order.each_with_index do |element, index |
      if element.weight == total_pallet_order[index-1].weight && element !=  total_pallet_order.first # because then you'd loop back to the last pallet in the array
        # puts "This one is: #{element.weight}, the previous one is #{total_pallet_order[index-1].weight}"
        element.weight_category = total_pallet_order[index-1].weight_category
        element.save
      elsif total_pallet_order.first.weight_category == "green" && total_pallet_order.first.weight == total_pallet_order.second.weight
        total_pallet_order.second.weight_category = "green"
        total_pallet_order.second.save
      end
    end
  end

  def assign_pallet_priority_categories
    self.pallets.each do |pallet|
      if pallet.priority == "first-priority" || pallet.priority == "second-priority"
        pallet.priority_category = "green"
      elsif pallet.priority == "third-priority" || pallet.priority == "forth-priority"
        pallet.priority_category = "amber"
      else
        pallet.priority_category = "red"
      end
    end
    self.pallets.each{|pallet| pallet.save}
  end
end
  # def single_lightest_pallet_set_to_green # StorageArea.all[1].single_lightest_pallet_set_to_green
  #   if total_pallet_order.first.weight < total_pallet_order.second.weight
  #     total_pallet_order.first.weight_category = "green"
  #   end
  # end

  # def single_heaviest_pallet_set_to_red # StorageArea.all[1].single_heaviest_pallet_set_to_red
  #   if total_pallet_order.last.weight > total_pallet_order[-2].weight
  #     total_pallet_order.last.weight_category = "red"
  #   end
  # end
