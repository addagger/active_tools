# DOCS ARE UNDER CONSTRUCTION

### For now, the most usable feature of active tools is 'custom counters' - my implementation of <t>counter through</t> solution

#### Look here! Typical data structure

Country

    class Country # has 'products_count' column
      ...
    end

Made in ...

    class MadeIn # has 'products_count' column
      belongs_to :country
      
      custom_counter_cache_for :country => {:made_ins_count => 1, :products_count => :products_count}
      
      # So, when MadeIn created/deleted, Country's 'made_ins_count' incremented/decremented by 1 and 'products_count' by MadeIn's 'products_count' value
      ...
    end

Category (has parent)

    class Category # has 'products_count' column
      acts_as_nested_set # has parent and children (!)

      custom_counter_cache_for "parent*" => {:children_count => 1, :products_count => :products_count}

      # So, when Category created/deleted, parent's 'children_count' incremented/decremented by 1 and 'products_count' by Category's 'products_count' value

    end

Brand name

    class Brand # has 'products_count' column
      ...
    end

Product itself

    class Product < ActiveRecord::Base
      belongs_to :category
      belongs_to :brand
      belongs_to :made_in
      
      custom_counter_cache_for :made_in => {:products_count => 1, :country => {:products_count => 1}}, :category => {:products_count => 1, "parent*" => {:products_count => 1}}, :brand => {:products_count => 1}
  
      # You can use nested options... it is very very useful :)
  
    end

Thanks

# ActiveTools

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'active_tools'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_tools

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
