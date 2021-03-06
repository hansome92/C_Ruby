require 'spec_helper'

describe Project::StateMachineHandler do
  let(:user){ create(:user) }

  describe "state machine" do
    let(:project) { create(:project, state: 'draft', online_date: nil) }

    describe '#draft?' do
      subject { project.draft? }
      context "when project is new" do
        it { should be_true }
      end
    end

    describe '.push_to_draft' do
      subject do
        project.reject
        project.push_to_draft
        project
      end
      its(:draft?){ should be_true }
    end

    describe '#rejected?' do
      subject { project.rejected? }
      before do
        project.push_to_draft
        project.reject
      end
      context 'when project is not accepted' do
        it { should be_true }
      end
    end

    describe '#reject' do
      before { project.update_attributes state: 'draft' }
      subject do
        project.should_receive(:notify_observers).with(:from_draft_to_rejected)
        project.reject
        project
      end
      its(:rejected?){ should be_true }
    end

    describe '#push_to_trash' do
      let(:project) { create(:project, permalink: 'my_project', state: 'draft') }

      subject do
        project.push_to_trash
        project
      end

      its(:deleted?) { should be_true }
      its(:permalink) { should == "deleted_project_#{project.id}" }
    end

    describe '#approve' do
      before { project.push_to_draft }

      subject do
        project.should_receive(:notify_observers).with(:from_draft_to_online)
        project.approve
        project
      end

      its(:online?){ should be_true }
      it('should call after transition method to notify the project owner'){ subject }
      it 'should persist the online_date' do
        project.approve
        expect(project.online_date).to_not be_nil
      end
    end

    describe '#online?' do
      before do
        project.push_to_draft
        project.approve
      end
      subject { project.online? }
      it { should be_true }
    end

    describe '#finish' do
      let(:main_project) { create(:project, goal: 30_000, online_days: -1) }
      subject { main_project }

      context 'when project is not approved' do
        before do
          main_project.update_attributes state: 'draft'
        end
        its(:finish) { should be_false }
      end

      context 'when project is expired and the sum of the pending contributions and confirmed contributions dont reached the goal' do
        before do
          create(:contribution, value: 100, project: subject, created_at: 2.days.ago)
          subject.finish
        end

        its(:failed?) { should be_true }
      end

      context 'when project is expired and have recent contributions without confirmation' do
        before do
          create(:contribution, value: 30_000, project: subject, state: 'waiting_confirmation')
          subject.finish
        end

        its(:waiting_funds?) { should be_true }
      end

      context 'when project already hit the goal and passed the waiting_funds time' do
        before do
          main_project.update_attributes state: 'waiting_funds'
          subject.stub(:pending_contributions_reached_the_goal?).and_return(true)
          subject.stub(:reached_goal?).and_return(true)
          subject.online_date = 2.weeks.ago
          subject.online_days = 0
        end

        context "when campaign type is all_or_none" do
          before do
            subject.finish
          end

          its(:successful?) { should be_true }
        end

        context "when campaign type is flexible" do
          before do
            main_project.update_attributes campaign_type: 'flexible'
            subject.finish
          end

          its(:successful?) { should be_true }
        end
      end

      context 'when project already hit the goal and still is in the waiting_funds time' do
        before do
          subject.stub(:pending_contributions_reached_the_goal?).and_return(true)
          subject.stub(:reached_goal?).and_return(true)
          create(:contribution, project: main_project, user: user, value: 20, state: 'waiting_confirmation')
          main_project.update_attributes state: 'waiting_funds'
        end

        context "when project is all_or_none" do
          before do
            subject.finish
          end
          its(:successful?) { should be_false }
        end

        context "when project is flexible" do
          before do
            main_project.update_attributes campaign_type: 'flexible'
            subject.finish
          end

          its(:successful?) { should be_false }
        end
      end

      context 'when project not hit the goal' do
        let(:user) { create(:user) }
        let(:contribution) { create(:contribution, project: main_project, user: user, value: 20, payment_token: 'ABC') }

        before do
          contribution
          subject.online_date = 2.weeks.ago
          subject.online_days = 0
        end

        context "when project is all_or_none" do
          before do
            subject.finish
          end

          its(:failed?) { should be_true }

          it "should generate credits for users" do
            contribution.confirm!
            user.reload
            user.credits.should == 20
          end
        end

        context "when project is flexible" do
          before do
            subject.update_attributes campaign_type: 'flexible'
            subject.finish
          end

          its(:failed?) { should be_false }

          it "should generate credits for users" do
            contribution.confirm!
            user.reload
            user.credits.should == 0
          end
        end
      end
    end
  end
end
