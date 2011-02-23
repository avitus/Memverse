= map_by_method by Dr Nic

== Installation

    gem install map_by_method
    
== Usage

    > a = ["1", "2", "3"]
    > a.map_by_to_i
    => [1, 2, 3]

 Can be used with ActiveRecord associations (since 0.7.0)
 
    > company = Company.find_by_name "Dr Nic Academy"
    > company.employees.count
    => 1
    > company.employees.map_by_name
    => ["Dr Nic"]
    
 Why use this?
 
 I think its much easier to type and read than its two equivalents:
   
    > company.employees.map { |employee| employee.name }
    or
    > company.employees.map &:name
  
