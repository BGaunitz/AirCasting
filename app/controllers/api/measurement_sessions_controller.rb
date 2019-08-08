module Api
  class MeasurementSessionsController < BaseController
    # TokenAuthenticatable was removed from Devise in 3.1
    # https://gist.github.com/josevalim/fb706b1e933ef01e4fb6
    before_action :authenticate_user_from_token!, only: :create
    before_action :authenticate_user!, only: :create

    respond_to :json

    def create
      GoogleAnalytics.new.register_event('Measurement Sessions#create')

      if ActiveModel::Type::Boolean.new.cast(params[:compression])
        decoded = Base64.decode64(params[:session])
        unzipped = AirCasting::GZip.inflate(decoded)
      else
        unzipped = params[:session]
      end
      photos = params[:photos] || []

      data = deep_symbolize ActiveSupport::JSON.decode(unzipped)
      data[:type] = 'MobileSession' # backward compatibility

      session = SessionBuilder.new(data, photos, current_user).build!

      if session
        render json: session_json(session), status: :ok
      else
        head :bad_request
      end
    end

    def export
      GoogleAnalytics.new.register_event('Measurement Sessions#export')

      service = Csv::ExportSessionsToCsv.new

      begin
        zip_path = service.call(params[:session_ids] || [])
        zip_file = File.read(zip_path)
        zip_filename = File.basename(zip_path)

        send_data zip_file,
                  type: Mime.fetch(:zip),
                  filename: zip_filename,
                  disposition: 'attachment'
      ensure
        service.clean
      end
    end

    private

    def session_json(session)
      {
        location: short_session_url(session, host: A9n.host_),
        notes:
          session.notes.map do |note|
            { number: note.number, photo_location: photo_location(note) }
          end
      }
    end
  end
end
