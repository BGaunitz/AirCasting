require 'rails_helper'

describe Stream do
  describe '#build_measurements!' do
    let(:stream) { FactoryBot.create(:stream) }
    let(:measurement) { FactoryBot.create(:measurement, stream: stream) }
    let(:measurement_data) { double('measurement data') }

    before do
      expect(Measurement).to receive(:new).with(measurement_data).and_return(
        measurement
      )
      expect(measurement).to receive(:stream=).with(any_args) { |x|
        x.id == stream.id
      }
      expect(Measurement).to receive(:import).with(any_args) do |measurements|
        expect(measurements).to include measurement
        import_result
      end
    end

    context 'the measurements are valid' do
      let(:import_result) { double(failed_instances: []) }

      it 'should import the measurements' do
        expect(Stream).to receive(:update_counters).with(
          stream.id,
          measurements_count: 1
        )

        stream.build_measurements!([measurement_data])
      end
    end

    context 'the measurements are invalid' do
      let(:import_result) { double(failed_instances: [1, 2, 3]) }

      it 'should cause an error' do
        expect {
          stream.build_measurements!([measurement_data])
        }.to raise_error(
          'Measurement import failed! Failed instances: [1, 2, 3]'
        )
      end
    end
  end

  describe '.as_json' do
    it 'should include stream size and measurements' do
      stream = FactoryBot.create(:stream)

      actual = stream.as_json(methods: %i[measurements])

      expect(actual['size']).not_to be_nil
      expect(actual['measurements']).not_to be_nil
    end
  end

  describe 'scope' do
    let(:user) { FactoryBot.create(:user) }
    let(:user2) { FactoryBot.create(:user) }
    let(:session) { FactoryBot.create(:mobile_session, user: user) }
    let(:session2) { FactoryBot.create(:mobile_session, user: user2) }
    let(:stream) do
      FactoryBot.create(:stream, sensor_name: 'Sensor1', session: session)
    end
    let(:stream2) do
      FactoryBot.create(:stream, sensor_name: 'Sensor2', session: session2)
    end

    describe '#with_sensor' do
      it 'returns sensor with specified name' do
        streams = Stream.with_sensor(stream.sensor_name)
        expect(streams).to include stream
        expect(streams).not_to include stream2
      end
    end

    describe '#with_usernames' do
      context 'no user names' do
        it 'returns all streams' do
          expect(Stream.with_usernames([])).to include stream, stream2
        end
      end

      context 'one user name' do
        it 'returns on streams with that user associated' do
          streams = Stream.with_usernames([user.username])
          expect(streams).to include stream
          expect(streams).not_to include stream2
        end
      end

      context 'multiple user names' do
        it 'returns all streams with those usernames' do
          expect(
            Stream.with_usernames([user.username, user2.username])
          ).to include stream, stream2
        end
      end
    end

    describe '#mobile' do
      it 'returns only mobile streams' do
        mobile_session = create_mobile_session!
        mobile_stream = create_stream!(session: mobile_session)
        fixed_session = create_fixed_session!
        create_stream!(session: fixed_session)

        expect(Stream.mobile).to contain_exactly(mobile_stream)
      end
    end
  end

  describe '#fixed?' do
    it 'with a fixed stream it returns true' do
      fixed_stream = create_stream!(session: create_fixed_session!)

      expect(fixed_stream.fixed?).to eq(true)
    end

    it 'with a mobile stream it returns false' do
      mobile_stream = create_stream!(session: create_mobile_session!)

      expect(mobile_stream.fixed?).to eq(false)
    end
  end

  describe '#last_hour_average' do
    it 'calculates the average out of the measurements recorded in the last hour' do
      stream = create_stream!(session: create_fixed_session!)
      now = DateTime.current
      create_measurement!(stream: stream, value: 1, time: now)
      create_measurement!(stream: stream, value: 2, time: now - 1.second)

      actual = stream.last_hour_average

      expect(actual).to eq(1.5)
    end
  end
end
