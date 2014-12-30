class Api::V1::MemversesController < Api::V1::ApiController

  doorkeeper_for :all  # Require access token for all actions

  version 1

  # The list of verses is paginated for 5 minutes, the verse itself is cached
  # until it's modified (using Efficient Validation)
  caches :index, :show, :caches_for => 5.minutes

  def index
    mvs = current_resource_owner.memverses
    mvs = params[:sort] ? mvs.order(params[:sort]) : mvs.canonical_sort

    expose mvs.page( params[:page] )
  end

  def show
    expose memverse
  end

  def update
    memverse.supermemo( params[:q].to_i )
    expose memverse
  end

  def create

    vs = Verse.find(params[:id])

    if vs and current_resource_owner

      # We need to lock the user in order to prevent a race condition when two memverses are created simultaneously
      # Without the lock, adding two adjacent verses occasionally results in two separate passages
      ActiveRecord::Base.transaction do

        current_resource_owner.lock! # Hold pessimistic user lock until memverse has been created and all hooks have executed

        if current_resource_owner.has_verse_id?(vs)
          error! :bad_request, metadata: {reason: 'Already added previously'}
        elsif current_resource_owner.has_verse?(vs.book, vs.chapter, vs.versenum)
          error! :bad_request, metadata: {reason: 'Already exists in different translation'}
        else
          # Save verse as a memory verse for user
          begin
            mv = Memverse.create(user: current_resource_owner, verse: vs)
          rescue Exception => e
            Rails.logger.error("=====> [Memverse save error (API)] Exception while saving #{vs.ref} for user #{current_resource_owner.id}: #{e}")
          else
            expose mv, status: :created  # added a new verse
          end
        end

      end # of transaction

    else
      error! :bad_request, metadata: {reason: 'Could not find verse or user'}
    end

  end

  def destroy
    memverse.destroy
    redirect_to memverses_path( version: 1 )
  end

  private

  def memverse
    @memverse ||= current_resource_owner.memverses.find( params[:id] )
  end

end