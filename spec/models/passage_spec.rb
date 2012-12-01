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

  # ALV: This would be nice to do but not sure exactly what I'm trying to achieve here
  # it "should create a new instance from a memverse" do
  #   @verse = Verse.create!(:book_index => 1, :book => "Genesis", :chapter => 12, :versenum => 1, :text => "This is a test", :translation => "NIV")
  #   @mv    = Memverse.create!(:user => @user, :verse => @verse)
  #   @psg   = Passage.create!( @mv.attributes, @mv.verse.attributes )
  # end

  describe "combining two passages" do

    before(:each) do

      # Automatically generates user through Factory
      @psg1 = FactoryGirl.create(:passage, :book => 'Luke', :chapter => 2, :first_verse => 2, :last_verse => 4)
      @psg2 = FactoryGirl.create(:passage, :book => 'Luke', :chapter => 2, :first_verse => 5, :last_verse => 8)

      @mvgrp1 = Array.new
      @mvgrp2 = Array.new

      for i in 2..4
        verse   = FactoryGirl.create(:verse, :book_index => 42, :book => "Luke", :chapter => 2, :versenum => i, :text => "Christmas with angels and shepherds")
        mv      = FactoryGirl.create(:memverse, :user => @user, :verse => verse, :passage => @psg1)
        mv.passage = @psg1
        mv.save
        @mvgrp1 << mv
      end

      for i in 5..8
        verse   = FactoryGirl.create(:verse, :book_index => 42, :book => "Luke", :chapter => 2, :versenum => i, :text => "Christmas with angels and shepherds")
        mv      = FactoryGirl.create(:memverse, :user => @user, :verse => verse, :passage => @psg2)
        mv.passage = @psg2
        mv.save
        @mvgrp2 << mv
      end

    end

    it "should merge two passages when the missing memverse is added" do

      puts "In test: Passage 2 belongs to #{@psg2.user.name}"
      puts "In test: mvgrp2 length is #{@mvgrp2.length}"
      puts "In test: Passage 2 has #{@psg2.memverses.length} verses in it."
      puts "In test: first element in mvgrp2: #{@mvgrp2.first.inspect}"
      puts "In test: first element in mvgrp2 belongs to passage: #{@mvgrp2.first.passage.inspect}"
      puts "In test: Passage 2: #{@psg2.inspect}"

      expect {
        @psg1.combine_with( @psg2 )
      }.to change(Passage, :count).by(-1)

      @psg1.first_verse.should == 2
      @psg1.last_verse.should  == 8

      @mvgrp2.first.passage.id.should == @psg1.id  # Now associated with new passage
    end

  end




end
