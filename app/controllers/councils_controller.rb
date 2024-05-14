class CouncilsController < ApplicationController
  def index
    @councils = Council.all.order(:name)
  end

  def show
    @council = Council.find(params[:id])
    # Take the 10 most recent meetings with a date in the past
    @meetings = @council.meetings.includes(:council, :documents, :committee).where('date < ?', Date.today).order(date: :desc).take(10)
    @decisions = @council.decisions.includes(:council, :decision_classifications).order(date: :desc).take(10)
  end
end
