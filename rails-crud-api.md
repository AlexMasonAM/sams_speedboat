#Building a Rails API:  Speedy Sam's Speedboat Shop

##Learning objectives
* Build a Rails API that serves JSON
* Follow a TDD workflow
* Write integration tests using RSpec's request specs
* Learn how to namespace our API routes
* Review some common HTTP response status codes


##A few words about testing our API
Our API will be responsible for returning (at most) two things:  an HTTP response status code and (sometimes) a response body.  Today, we will be writing integration tests to make sure that our API behaves as we expect it to.

Our integration tests will simulate the interaction between a client and our server.  For example, the client will submit an HTTP GET request for all of the speedboat records and--assuming that the request was sent properly--the server will respond with an appropriate status code and a list of speedboats formatted as JSON.

To write our tests, we will use RSpec's request specs.  It should be pointed out that these integration tests aren't a replacement for good model tests.  You should still be writing tests for your models, especially if they have lots of attributes, complex validations, and/or complex associations with other models.

##Setting up our application
1. `$ rails new speedboat-api -d postgresql -T`

2. `$ rake db:create`

3.  Add RSpec and Factory Girl to your Gemfile:

    ```ruby
        group :development, :test do
          gem "rspec-rails"
          gem "factory_girl_rails"
        end
    ```

4. `$ bundle`

5. `$ rails g rspec:install`


##Building our application
1. Let's get started by generating our model:

    ```
        $ rails g model speedboat brand model_number image_url wholesale_price:float retail_price:float in_stock:boolean
    ```

    **Note** -- This generator creates the following files:

    * a migration file to create a speedboats table in our database
    * our actual model file
    * a new model spec file
    * a new factory file

2. Let's go ahead and run `$ rake db:migrate`.

3. We're not going to be writing model tests today (though it would definitely be a good idea to have model tests in real life).  Instead, we're going to be writing integration tests to test for the HTTP response status code and the response body.

    That means that we need to create a new folder in our spec directory called "api".

    Inside this new folder we will create a file called `speedboats_spec.rb`.

    ```
    $ mkdir spec/api
    $ touch spec/api/speedboats_spec.rb
    ```

4.  Okay, let's tackle our first feature.  We want our API to return a list of all speedboats.  Let's write a test:

    ```ruby
        require "rails_helper"

        describe "Speedboats API", :type => :request do

          it "returns a list of speedboats" do
            FactoryGirl.create_list(:speedboat, 10)

            get "/api/speedboats"

            expect(response).to have_http_status 200

            speedboats = JSON.parse(response.body)
            expect(speedboats.count).to eq(10)
          end
        end
    ```

    * Alright, the next error has to do with our routes (we don't have any yet!).  Let's go fix it:

    ```ruby
          namespace :api do
            resources :speedboats
          end
    ```
    * The next error we will get is `ActionController::RoutingError: uninitialized constant Api` because we haven't defined Api anywhere.  We can fix this error by doing the following:

        * create a directory called "api" inside the controllers directory.
        * inside our api directory, create a new file called "speedboats_controller.rb".
        
        ```
        $ mkdir app/controllers/api 
        $ touch app/controllers/api/speedboats_controller.rb
        ```
        
        * Now we need to write our controller.  It should look like this:

            ```ruby
                module Api
                  class SpeedboatsController < ApplicationController
                  end
                end
            ```
    * Now our test tells us that we don't have an index action in our controller.  We know how to fix that!

    ```ruby
        module Api
          class SpeedboatsController < ApplicationController
            def index
            end
          end
        end
    ```
    * The next error we should get is something about a missing template.  When someone sends a GET request to `/speedboats`, we want to respond with json so let's make that happen by adding the following to our controller:

    ```ruby
        module Api
          class SpeedboatsController < ApplicationController
            def index
              speedboats = Speedboat.all
              render json: speedboats.to_json
            end
          end
        end
    ```
    * Boom!  Our test passes!

5. Now let's tackle getting our API to return a single speedboat.  We'll start by writing a test (duh!):

     ```ruby
        it "returns a specific speedboat" do
          speedboat = FactoryGirl.create(:speedboat)

          get "/api/speedboats/#{speedboat.id}"

          expect(response).to have_http_status 200
          expect(response.body).to eq(speedboat.to_json)
        end
     ```

     * The next error is that we don't have a show action in our speedboats controller.  We can fix that!

     ```ruby
        #in our speedboats_controller.rb file
        def show
        end
     ```

     * That gives us an error saying that the template is missing.  That's because we haven't told our controller what to return and Rails isn't able to infer it.  Let's tell it what to do:

     ```ruby
        def show
          speedboat = Speedboat.find(params[:id])
          render json: speedboat.to_json
        end
     ```

     * Sweet like bear meat!  That gets our test to pass.

6. Let's get serious and tackle creating a new speedboat.  You know we're going to start with a test.  Let's do it!

    Because we are going to be using request headers in several of our tests, we can DRY up our code by adding the following code just inside our `describe` block:

    ```ruby
      describe "Speedboats API", :type => :request do

        let(:request_headers) { { "Accept" => "application/json", "Content-type" => "application/json" } }

        #rest of the code omitted for brevity
      end
    ```

	* And the test

    ```ruby
        it "creates a new speedboat" do
          speedboat_attributes = { "speedboat" => FactoryGirl.attributes_for(:speedboat) }.to_json

          post "/api/speedboats", speedboat_attributes, request_headers

          speedboat = JSON.parse(response.body)
          expect(response).to have_http_status 201
          expect(response.location).to eq("http://www.example.com/api/speedboats/#{speedboat['id']}")
        end
    ```

    * Now our failing test tells us that we need a controller action:

    ```ruby
        def create
        end
    ```

    * Now is that oh so familiar missing template error.  We need to actually create something in our create action and then return something to the client:

    ```ruby
        def create
          speedboat = Speedboat.new(speedboat_params)

          if speedboat.save
            respond_with speedboat, location: [:api, speedboat]
            render json: speedboat.to_json, location: [:api, speedboat]
          end
        end
    ```
    
    * create method for speedboat_params
    *
    ```
      private
    def speedboat_params
      params.require(:speedboat).permit(:brand, :model_number, :image_url, :wholesale_price, :retail_price, :in_stock)
    end
	```

    * Our test passes now, but does it really work as we expect?  Let's try sending a POST request with curl (first we will need to make sure that our Rails server is running):

    ```
        $ curl -i -X POST -d 'speedboat[brand]=yamaha' http://localhost:3000/api/speedboats
    ```

    When we run this curl command, we can see that we are getting back a 422 status code (Unprocessable Entity).  This happens because Rails checks the incoming request for an authenticity token if the request is a POST, PUT, PATCH, or DELETE.

    This is set up as the default for all our controllers in our Application Controller.  It's that line that says `protect_from_forgery with: :exception`.  The reason why our test didn't catch this is because this feature is turned off by default in our test environment.  We can see this on line 27 of our test.rb file.

    To fix this, we need to add the following line of code in our speedboats controller to override this default behavior: `protect_from_forgery with: :null_session`.

    Now, if we run that curl command again, we will see that the POST request is successful and that it returns our newly created speedboat as JSON.

7. Let's tell our create action what to do if a record doesn't save because of a failed validation.  We'll start with a test:

    ```ruby
        it "does not create a new speedboat with pattern nil" do
          speedboat_attributes = { "speedboat" => FactoryGirl.attributes_for(:speedboat, model_number: nil) }.to_json

          post "/api/speedboats", speedboat_attributes, request_headers

          expect(response).to have_http_status 422
        end
    ```

    * Let's start by adding a simple validation to our model so that we can see what happens if a record doesn't save:

    ```ruby
        class Speedboat < ActiveRecord::Base
          validates : model_number, presence: true
        end
    ```

    * Now, in our controller we will add an else block to our create action:

    ```ruby
        def create
          speedboat = Speedboat.new(speedboat_params)

          if speedboat.save
            render json: speedboat.to_json, location: [:api, speedboat]
          else
            render json: speedboat.to_json
          end
        end
    ```

    * Let's try our curl command again to see what happens:

    ```
        $ curl -i -X POST -d 'speedboat[brand]=yamaha' http://localhost:3000/api/speedboats
    ```

    * We can see that the response includes a `422 Unprocessable Entity` status code and it returns the error messages as JSON (in this case, we get `{"model_number":["can't be blank"]}`).

8.  Alright, time to tackle updating a speedboat.  We're gonna need a test for that!

    ```ruby
        it "updates a specific speedboat" do
          speedboat = FactoryGirl.create(:speedboat)
          speedboat_attributes = { "speedboat" => { "model_number" => "S1000" } }.to_json

          patch "/api/speedboats/#{speedboat.id}", speedboat_attributes, request_headers
          puts response.body
          expect(response).to have_http_status 204
          expect(speedboat.reload.model_number).to eq("S1000")
        end
    ```


    * Next error:  no controller action!  Let's define an update action in our speedboats controller:

    ```ruby
        def update
        end
    ```

    * Now we get the missing template error.  Let's address that:

    ```ruby
        def update
          speedboat = Speedboat.find(params[:id])
          if speedboat.update_attributes(speedboat_params)
            head 204
          end
        end
    ```

    * That makes our test pass!  Notice that we aren't returning the newly updated speedboat object in the response body.  We're only sending back a response header with a 204 status code, which is used for a successful request that doesn't have a response body.

    * But what if an update fails for some reason, like not meeting a validation? Let's write a test:

    ```ruby
        it "is unsuccessful on update without a pattern attribute" do
          speedboat = FactoryGirl.create(:speedboat)
          speedboat_attributes = { "speedboat" => { "model_number" => nil } }.to_json

          patch "/api/speedboats/#{speedboat.id}", speedboat_attributes, request_headers
          expect(response).to have_http_status 422
        end
    ```

    * We get an error that we have a missing template.  We need to add an `else` block in our update action:

    ```ruby
        def update
          speedboat = Speedboat.find(params[:id])
          if speedboat.update_attributes(speedboat_params)
            head 204
          else
            render json: speedboat.to_json
          end
        end
    ```

    * Another passing test...you're a hero!

9. We're so close to having full CRUD...let's tackle destroying a resource!  As always, we'll start with a test:

    ```ruby
        it "destroys a specific speedboat" do
          speedboat = FactoryGirl.create(:speedboat)

          delete "/api/speedboats/#{speedboat.id}"
          expect(response).to have_http_status 204
        end
    ```

    * Next error:  no controller action for "destroy".  Let's write it:

    ```ruby
        def destroy
        end
    ```

    * Let's fix that missing template error:

    ```ruby
        def destroy
          speedboat = Speedboat.find(params[:id])
          speedboat.destroy
          head 204
        end
    ```

    * When we run our test, we see that everything passes.  Congratulations, you just built your first full CRUD Rails API!  And the best part: you used TDD!

