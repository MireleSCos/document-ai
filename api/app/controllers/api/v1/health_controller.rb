module Api
  module V1
    class HealthController < ApplicationController
      def show
        render json: { status: "ok", service: "workverse-document-ai" }
      end
    end
  end
end
