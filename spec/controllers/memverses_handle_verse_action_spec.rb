require 'rails_helper'

RSpec.describe MemversesController, type: :controller do
  describe "POST #handle_verse_action" do
    let(:user) { FactoryBot.create(:user) }
    let!(:verse1) { FactoryBot.create(:verse) }
    let!(:verse2) { FactoryBot.create(:verse) }
    let!(:memverse1) { FactoryBot.create(:memverse, user: user, verse: verse1) }
    let!(:memverse2) { FactoryBot.create(:memverse, user: user, verse: verse2) }

    before do
      sign_in user
    end

    context "when Show button is clicked" do
      context "with no verses selected" do
        it "redirects to manage_verses with flash message" do
          post :handle_verse_action, params: { "Show" => "Show Selected" }
          
          expect(response).to redirect_to(manage_verses_path)
          expect(flash[:notice]).to eq("Please select verses using the checkboxes in the first column.")
        end
      end

      context "with one verse selected" do
        it "redirects to the single verse view" do
          post :handle_verse_action, params: { 
            "Show" => "Show Selected",
            mv: [memverse1.id.to_s]
          }
          
          expect(response).to redirect_to(memory_verse_path(memverse1))
        end
      end

      context "with multiple verses selected" do
        it "renders the show template with multiple verses" do
          post :handle_verse_action, params: { 
            "Show" => "Show Selected",
            mv: [memverse1.id.to_s, memverse2.id.to_s]
          }
          
          expect(response).to render_template(:show)
          expect(assigns(:mv_list)).to match_array([memverse1, memverse2])
        end
      end
    end

    context "when Prompt button is clicked" do
      context "with no verses selected" do
        it "redirects to manage_verses with flash message" do
          post :handle_verse_action, params: { "Prompt" => "Show Prompt" }
          
          expect(response).to redirect_to(manage_verses_path)
          expect(flash[:notice]).to eq("Please select verses using the checkboxes in the first column.")
        end
      end

      context "with verses selected" do
        it "renders the show_prompt template" do
          post :handle_verse_action, params: { 
            "Prompt" => "Show Prompt",
            mv: [memverse1.id.to_s, memverse2.id.to_s]
          }
          
          expect(response).to render_template(:show_prompt)
          expect(assigns(:mv_list)).to match_array([memverse1, memverse2])
        end

        it "sets up the verse list correctly" do
          post :handle_verse_action, params: { 
            "Prompt" => "Show Prompt",
            mv: [memverse1.id.to_s, memverse2.id.to_s]
          }
          
          mv_list = assigns(:mv_list)
          expect(mv_list.size).to eq(2)
          expect(mv_list.map(&:verse)).to match_array([verse1, verse2])
        end
      end
    end

    context "when Delete button is clicked" do
      it "calls delete_verses action" do
        expect(controller).to receive(:delete_verses)
        
        post :handle_verse_action, params: { 
          "Delete" => "Delete Selected",
          mv: [memverse1.id.to_s]
        }
      end
    end

    context "when no recognized button is clicked" do
      it "redirects to manage_verses" do
        post :handle_verse_action, params: { mv: [memverse1.id.to_s] }
        
        expect(response).to redirect_to(manage_verses_path)
      end
    end
  end

  describe "POST #show_prompt (direct route)" do
    let(:user) { FactoryBot.create(:user) }
    let!(:verse1) { FactoryBot.create(:verse) }
    let!(:memverse1) { FactoryBot.create(:memverse, user: user, verse: verse1) }

    before do
      sign_in user
    end

    it "renders show_prompt template when verses are provided" do
      post :show_prompt, params: { mv: [memverse1.id.to_s] }
      
      expect(response).to render_template(:show_prompt)
      expect(assigns(:mv_list)).to eq([memverse1])
    end

    it "redirects when no verses are provided" do
      post :show_prompt, params: {}
      
      expect(response).to redirect_to(manage_verses_path)
      expect(flash[:notice]).to eq("Please select verses using the checkboxes in the first column.")
    end
  end
end