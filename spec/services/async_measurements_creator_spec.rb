require "spec_helper"

describe AsyncMeasurementsCreator do
  it "with 500 measurement or less it queues them in the default queue" do
    measurements_creator_worker = class_double(MeasurementsCreatorWorker)
    subject = AsyncMeasurementsCreator.new(measurements_creator_worker: measurements_creator_worker)
    stream = Stream.new
    stream_id = 1
    stream.id = stream_id
    measurement_attributes = [{}] * 500

    expect(measurements_creator_worker)
      .to receive(:set)
      .with(queue: :default)
      .once
      .and_return(measurements_creator_worker)
    expect(measurements_creator_worker)
      .to receive(:perform_async)
      .with(stream_id, measurement_attributes)
      .once

    subject.call(stream: stream, measurements_attributes: measurement_attributes)
  end

  it "with 501 measurements it queues them in the default queue in groups of 500" do
    measurements_creator_worker = class_double(MeasurementsCreatorWorker)
    subject = AsyncMeasurementsCreator.new(measurements_creator_worker: measurements_creator_worker)
    stream = Stream.new
    stream_id = 1
    stream.id = stream_id
    measurement_attributes = [{}] * 501

    expect(measurements_creator_worker)
      .to receive(:set)
      .with(queue: :default)
      .once
      .and_return(measurements_creator_worker)
    expect(measurements_creator_worker)
      .to receive(:perform_async)
      .with(stream_id, measurement_attributes)
      .once
    expect(measurements_creator_worker)
      .to receive(:set)
      .with(queue: :default)
      .once
      .and_return(measurements_creator_worker)
    expect(measurements_creator_worker)
      .to receive(:perform_async)
      .with(stream_id, measurement_attributes)
      .once

    subject.call(stream: stream, measurements_attributes: measurement_attributes)
  end

  it "with 20_000 measurements it queues them in the slow queue in groups of 500" do
    measurements_creator_worker = class_double(MeasurementsCreatorWorker)
    subject = AsyncMeasurementsCreator.new(measurements_creator_worker: measurements_creator_worker)
    stream = Stream.new
    stream_id = 1
    stream.id = stream_id
    measurement_attributes = [{}] * 20_000

    expect(measurements_creator_worker)
      .to receive(:set)
      .with(queue: :slow)
      .exactly(40)
      .times
      .and_return(measurements_creator_worker)
    expect(measurements_creator_worker)
      .to receive(:perform_async)
      .with(stream_id, measurement_attributes)
      .exactly(40)
      .times

    subject.call(stream: stream, measurements_attributes: measurement_attributes)
  end
end
