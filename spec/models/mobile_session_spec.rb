# AirCasting - Share your Air!
# Copyright (C) 2011-2012 HabitatMap, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# You can contact the authors by email at <info@habitatmap.org>

require 'spec_helper'

describe MobileSession do
  let(:time_in_us) { Time.now.utc.in_time_zone("Eastern Time (US & Canada)") }

  describe '#local_time_range' do
    it "should include sessions with start_time_local or end_time_local inside time range" do
      time = Time.now

      from = time.hour * 60 + time.min
      to = (time.hour + 1) * 60 + time.min

      session = FactoryGirl.create(
        :mobile_session,
        :start_time_local => time - 1.minute,
        :end_time_local => time + 1.minute
      )
      session1 = FactoryGirl.create(
        :mobile_session,
        :start_time_local => time - 2.minute,
        :end_time_local => time - 1.minute
      )
      session2 = FactoryGirl.create(
        :mobile_session,
        :start_time_local => time + 61.minute,
        :end_time_local => time + 71.minute
      )

      MobileSession.local_time_range_by_minutes(from, to).all.should == [session]
    end
  end

  describe "#as_json" do
    let(:stream) { FactoryGirl.create(:stream) }
    let(:m1) { FactoryGirl.create(:measurement, :stream => stream) }
    let(:m1) { FactoryGirl.create(:measurement, :stream => stream) }
    let(:session) { FactoryGirl.create(:mobile_session, :streams => [stream]) }

    subject { session.as_json(:methods => [:measurements]) }

    it "should tell streams to include measurements" do
      a = subject.symbolize_keys[:streams].first
      b = stream.as_json

      a[1].should == b
    end

    it "should not provide own list of measurements" do
      subject.symbolize_keys[:measurements].should == []
    end
  end

  describe '.create' do
    let(:session) { FactoryGirl.build(:mobile_session) }

    it 'should call set_url_token' do
      session.should_receive(:set_url_token)
      session.save
    end
  end

  describe "#destroy" do
    let(:stream) { FactoryGirl.create(:stream) }
    let(:session) { FactoryGirl.create(:mobile_session, :streams => [stream]) }

    it "should destroy streams" do
      session.reload.destroy

      expect(Stream.exists?(stream.id)).to be(false)
    end
  end

  describe '.filter' do
    before { MobileSession.destroy_all }

    it 'should exclude not contributed sessions' do
      session1 = FactoryGirl.create(:mobile_session, :contribute => true)
      session2 = FactoryGirl.create(:mobile_session, :contribute => false)

      MobileSession.filter.all.should == [session1]
    end

    it 'should include explicitly requested but not contributed sessions' do
      session =  FactoryGirl.create(:mobile_session, :id => 1, :contribute => false)

      MobileSession.filter(:session_ids => [1]).all.should == [session]
    end

    it "#filter includes sessions overlapping the time range" do
      now = Time.now
      plus_one_hour_in_minutes = (now.hour + 1) * 60 + now.min
      plus_two_hours_in_minutes = (now.hour + 2) * 60 + now.min
      session = FactoryGirl.create(
        :mobile_session,
        :start_time_local => now,
        :end_time_local => now + 3.hours
      )

      actual = MobileSession.filter(:time_from => plus_one_hour_in_minutes, :time_to => plus_two_hours_in_minutes).all

      actual.should == [session]
    end

    it "#filter excludes sessions outside the time range" do
      now = Time.now
      plus_one_hour_in_minutes = (now.hour + 1) * 60 + now.min
      plus_two_hours_in_minutes = (now.hour + 2) * 60 + now.min
      session = FactoryGirl.create(
        :mobile_session,
        :start_time_local => now,
        :end_time_local => now + 1.second
      )

      actual = MobileSession.filter(:time_from => plus_one_hour_in_minutes, :time_to => plus_two_hours_in_minutes).all

      actual.should == []
    end

    it "should find sessions by usernames" do
      user_1 = FactoryGirl.create(:user, :username => 'foo bar')
      user_2 = FactoryGirl.create(:user, :username => 'john')
      session_1 = FactoryGirl.create(:mobile_session, :user => user_1)
      session_2 = FactoryGirl.create(:mobile_session, :user => user_2)

      MobileSession.filter(:usernames => 'foo bar    , biz').all.should == [session_1]
    end


    it "#filter when time range is the whole day it does not call local_time_range_by_minutes" do
      from = Session::FIRST_MINUTE_OF_DAY
      to = Session::LAST_MINUTE_OF_DAY

      Session.should_not_receive(:local_time_range_by_minutes).with(from, to)

      MobileSession.filter(:time_from => from, :time_to => to)
    end
  end

  describe '.filtered_json' do
    let(:data) { double('data') }
    let(:records) { double('records') }
    let(:json) { double('json') }

    it 'should return filter() as json' do
      MobileSession.should_receive(:filter).with(data).and_return(records)
      records.should_receive(:as_json).with(hash_including({:only => [:id, :title, :start_time_local, :end_time_local],
        :methods => [:username, :streams]})).and_return(json)

      MobileSession.filtered_json(data, 0, 50).should == json
    end
  end

  describe '#set_url_token' do
    let(:token) { double }
    let(:gen) { double(:generate_unique => token) }

    before do
      TokenGenerator.stub(:new => gen)
      subject.send(:set_url_token)
    end

    it 'sets url_token to one generated by TokenGenerator' do
      subject.url_token.should == token
    end
  end

  describe '#to_param' do
    let(:session) { MobileSession.new }

    subject { session.to_param }

    it { should == session.url_token }
  end

  describe "#sync" do
    let(:session) { FactoryGirl.create(:mobile_session) }
    let!(:note) { FactoryGirl.create(:note, :session => session) }
    let(:data) { { :tag_list => "some tag or other", :notes => [] } }

    before { session.reload.sync(data) }

    it "should normalize tags" do
      session.reload.tags.count.should == 4
    end

    it "should delete notes" do
      expect(Note.exists?(note.id)).to be(false)
    end
  end

  describe "#start_time" do
    it "keeps time info in UTC" do
      session = MobileSession.new
      time_in_utc = time_in_us.utc

      session.start_time = time_in_us
      session.start_time.to_s.should == time_in_utc.to_s
    end
  end

  describe "#end_time" do
    it "keeps time info in UTC" do
      session = MobileSession.new
      time_in_utc = time_in_us.utc

      session.end_time = time_in_us
      session.end_time.to_s.should == time_in_utc.to_s
    end
  end

  describe "#start_time_local" do
    it "keeps local time info" do
      session = FactoryGirl.build(:mobile_session)
      session.start_time_local = time_in_us

      session.save
      session.reload
      session.start_time_local.strftime('%FT%T').should == time_in_us.strftime('%FT%T')

    end
  end

  describe "#end_time_local" do
    it "keeps local time info" do
      session = FactoryGirl.build(:mobile_session)
      session.end_time_local = time_in_us
      session.save
      session.reload
      session.end_time_local.strftime('%FT%T').should == time_in_us.strftime('%FT%T')
    end
  end

end
