# encoding: utf-8
require 'spec_helper'

describe Passage do

  before(:each) do
    @user  = User.create!(:name => "Test User", :email => "test@memverse.com", :password => "secret", :password_confirmation => "secret")
  end

  it "should create a new instance given valid attributes" do
    @verse = Verse.create!(:book_index => 1, :book => "Genesis", :chapter => 12, :versenum => 1, :text => "This is a test", :translation => "NIV")
    @mv    = Memverse.create!(:user => @user, :verse => @verse)
    @psg   = Passage.create!(:user_id => @user, :length => 1, :reference => @mv.verse.ref,
                             :book => @mv.verse.book, :chapter => @mv.verse.chapter,
                             :first_verse => @mv.verse.versenum, :last_verse => @mv.verse.versenum,
                             :efactor => @mv.efactor, :test_interval => @mv.test_interval, :rep_n => 1)
  end

end
