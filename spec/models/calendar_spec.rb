require 'rails_helper'

RSpec.describe Calendar, type: :model do
  subject(:calendar) { create(:calendar) }

  describe 'attributes' do
    describe '#default' do
      before { expect(Calendar.pluck(:default)).to eq([true]) }

      context 'when set to true on creation' do
        subject(:calendar) { build(:calendar, default: true) }

        it 'stays true and sets all other calendars to default: false' do
          expect { calendar.tap(&:save).reload }.not_to change { calendar.default }
          expect(Calendar.where(default: true) - [calendar]).to be_empty
        end
      end

      context 'when set to true on update' do
        subject(:calendar) { create(:calendar, default: false) }
        before { calendar.default = true }

        it 'stays true and sets all other calendars to default: false' do
          expect { calendar.tap(&:save).reload }.not_to change { calendar.default }
          expect(Calendar.where(default: true) - [calendar]).to be_empty
        end
      end

      context 'when set to false on update' do
        it 'sets default: true on earliest-created calendar' do
          expect { Calendar.first.update(default: false) }
            .not_to change { Calendar.first.default }
        end
      end

      context 'when default calendar is destroyed' do
        subject!(:calendar) { create(:calendar, default: false) }

        it 'sets default: true on earliest-created remaining calendar' do
          expect { Calendar.first.destroy }
            .to change { calendar.reload.default }.to(true)
        end
      end
    end

    describe '#public_holidays' do
      subject(:calendar) do
        create(:calendar, ical_url: Rails.root.join('test', 'data', 'calendar', 'calendar1.ics'))
      end

      before { travel_to Time.zone.parse('2017-08-24T01:04:44Z0') }

      context 'on creation' do
        it 'is computed from iCal event data (implicitly via #sync), from one year before to three years after' do
          expect(calendar.public_holidays).to eq(
            '2016-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2017-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2018-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2019-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
          )
        end

        context 'with one-time and n-time (recurring) events' do
          subject(:calendar) do
            create(:calendar, ical_url: Rails.root.join('test', 'data', 'calendar', 'calendar3.ics'))
          end

          it 'accurately computes/imports events' do
            expect(calendar.public_holidays).to eq(
              '2016-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2016-12-26' => { 'active' => true, 'summary' => 'day3', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2016-12-28' => { 'active' => true, 'summary' => 'day5', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-01-26' => { 'active' => true, 'summary' => 'day3', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-02-26' => { 'active' => true, 'summary' => 'day3', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-03-26' => { 'active' => true, 'summary' => 'day3', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-04-26' => { 'active' => true, 'summary' => 'day3', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2018-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2019-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            )
          end
        end
      end
    end
  end

  describe '#sync' do
    subject(:calendar) do
      create(:calendar, ical_url: Rails.root.join('test', 'data', 'calendar', 'calendar1.ics'))
    end

    before { travel_to Time.zone.parse('2017-08-24T01:04:44Z0') }

    context 'when called explicitly after creation' do
      it 'writes #public_holidays to the cache (valid for 1 day)' do
        expect(Cache.get("CalendarIcal::#{calendar.id}")).to be(nil)

        expect { calendar.sync }
          .to change { Cache.get("CalendarIcal::#{calendar.id}") }
          .to(calendar.attributes.slice('public_holidays', 'ical_url').symbolize_keys)
      end

      context 'and neither current date nor iCal URL have changed' do
        it 'is idempotent' do
          expect { calendar.sync }
            .not_to change { calendar.public_holidays }
        end
      end

      context 'and current date has changed (past cache expiry)' do
        before do
          calendar  # create and sync
          travel 1.year
        end

        it 'appends newly computed event data to #public_holidays' do
          expect { calendar.sync }.to change { calendar.public_holidays }.to(
            '2016-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2017-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2018-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2019-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2020-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
          )
        end
      end

      context 'and iCal URL has changed' do
        before { calendar.assign_attributes(ical_url: Rails.root.join('test', 'data', 'calendar', 'calendar2.ics')) }

        it 'replaces #public_holidays with event data computed from new iCal URL' do
          expect { calendar.save }
            .to change { calendar.public_holidays }.to(
              '2016-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2016-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2018-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2018-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2019-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2019-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            )
        end
      end
    end
  end
end
