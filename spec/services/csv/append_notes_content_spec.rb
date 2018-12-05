require "spec_helper"

describe Csv::AppendNotesContent do
  let(:lines) { [] }
  let(:date) { DateTime.new(2018,8,20,11,16,44) }
  let(:latitude) { BigDecimal.new("40.68038924") }
  let(:longitude) { BigDecimal.new("-73.97631499") }
  let(:photo_url) { "http://aircasting.org/system/example.jpg" }
  let(:photo_file_name) { "example.jpg" }
  let(:note1) { { "text" => "Example Note", "date" => date, "latitude" => latitude, "longitude" => longitude, "photo_file_name" => photo_file_name } }
  let(:note2) { { "text" => "Example Note 2", "date" => date, "latitude" => latitude, "longitude" => longitude, "photo_file_name" => photo_file_name } }
  let(:expected_headers) { %w(Note Time Latitude Longitude Photo_Url) }

  it "appends correct headers" do
    data = build_data([note1])
    subject.call(lines, data)

    actual_headers = lines.first

    expect(actual_headers).to eq(expected_headers)
  end

  it "appends the content of the note" do
    data = build_data([note1])
    subject.call(lines, data)

    actual_note = lines.second

    expected_note = ["Example Note","2018-08-20T11:16:44",latitude,longitude,photo_url]
    expect(actual_note).to eq(expected_note)
  end

  it "appends correct content" do
    data = build_data([note1, note2])
    subject.call(lines, data)

    actual_content = lines

    expected_content = [
      expected_headers,
      ["Example Note","2018-08-20T11:16:44",latitude,longitude,photo_url],
      ["Example Note 2","2018-08-20T11:16:44",latitude,longitude,photo_url],
    ]
    expect(actual_content).to eq(expected_content)
  end

  private

  def build_data(notes)
    Csv::NotesData.new(
      "notes" => notes,
      "session_id" => 123
    )
  end
end
