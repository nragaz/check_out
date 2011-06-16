CheckOut
============

Let users `check out` Active Record instances and then release them when they're done editing.

Using `include CheckOut` in a model's class definition provides the following features:

  * Scopes:
    1. `checked_out_to(user)`
    2. `checked_out`
    3. `released` (inverse of `checked_out`)
    4. `available_to(user)`
  * Collection / scope methods:
    1. `check_out_all(user)`
    2. `release_all_checkouts(user)` (`user` is optional)
  * Instance methods:
    1. `checked_out?`
    2. `checked_out_to?(user)`
    3. `check_out(user)`
    4. `release(user)` (`user` is optional)
    5. `update_attributes_and_release(attributes)`

The model must have the following columns:

  * `checked_out_by_user_id` (integer)
  * `checked_out_by_user_type` (string)
  * `checked_out_at` (datetime)

Requires Rails ~> 3 and Ruby 1.9.2.

Usage
-----

  create_table "jobs" do |t|
    t.integer :checked_out_by_user_id
    t.string :checked_out_by_user_type
    t.datetime :checked_out_at
  end
  
  class Job < ActiveRecord::Base
    include CheckOut
  end
  
  # in 'edit' action
  
  job.checkout(user) # => job.checked_out_at = Time.now, etc.
  
  # in 'update' action
  
  job = Job.available_to(user).find(params[:id])
  job.update_attributes_and_release(params[:job])
  
The challenging thing is knowing when to release the record if the user decides not to make any changes (i.e. cancels) or just closes their browser.

I've found that by including `Job.release_all_checkouts(current_user)` in the 'index' action, I can avoid almost all conflicts. I also add an "unlock" action for manually overriding an existing checkout. A link to 'unlock' appears in a flash message if a user tries to edit a record that is already checked out.