require "rails_helper"
require "shared_examples/shared_examples_for_api_controllers"
require "support/helpers/api_helper.rb"
include ApiHelper

module ApiFlashcards
  RSpec.describe Api::V1::ReviewController, type: :controller do
    routes { ApiFlashcards::Engine.routes }

    describe "GET#index" do
      context "without credentials" do
        before { get :index }
        it_behaves_like "not authorized"
      end

      context "with incorrect credentials" do
        before do
          get :index,
              request.headers["Authorization"] = encode("some@test.com",
                                                        "nopass")
        end
        it_behaves_like "not authorized"       
      end

      context "with correct credentials" do
        include_context "with correct credentials" do
          let(:endpoint) do
            {
              verb: "get",
              method: "index"
            }
          end
        end
        it "responds with 200 status code" do
          expect(response.status).to eq(200)
        end
        it "responds with \'card_review\' key in response" do
          expect(json_response.has_key?("card_review")).to eq(true)
        end
        it "responds with only one card" do
          expect(json_response["card_review"]).not_to be_kind_of Array
        end
      end
    end

    describe "PUT#check" do
      context "without credentials" do
        before { put :check }
        it_behaves_like "not authorized"
      end

      context "with incorrect credentials" do
        before do
          put :check,
              request.headers["Authorization"] = encode("some@test.com",
                                                        "nopass")
        end
        it_behaves_like "not authorized"      
      end

      context "with correct credentials" do
        include_context "with correct credentials" do
          let(:endpoint) do
            { verb: "put", method: "check" }
          end
        end

        shared_examples "common response" do
          it "responds with 200 status code" do
            expect(response.status).to eq(200)
          end
        end

        context "when user provides correct translation" do
          let(:params) do
            {
              card_id: card.id,
              translated_text: "Translation"
            }
          end
          it_behaves_like "common response"
          it "responds with successful message"
        end

        context "when user made a typo" do
          let(:params) do
            {
              card_id: card.id,
              translated_text: "Translatio"
            }
          end
          it_behaves_like "common response"
          it "responds with typo message"
        end

        context "when user provides incorrect translation" do
          let(:params) do
            {
              card_id: card.id,
              translated_text: "Something"
            }
          end
          it_behaves_like "common response"
          it "responds with failure message"
        end

      end
    end
  end
end