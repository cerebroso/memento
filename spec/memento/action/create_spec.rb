require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe Memento::Action::Create, "when object is created" do
  before do
    setup_db
    setup_data
    Memento.instance.start(@user)
    @project = Project.create!(:name => "P1", :closed_at => 3.days.ago).reload
    Memento.instance.stop
  end
  
  after do
    shutdown_db
  end
    
  it "should create memento_state for ar-object with no data" do
    Memento::State.count.should eql(1)
    Memento::State.first.action_type.should eql("create")
    Memento::State.first.record.should eql(@project) # it was destroyed, remember?
    Memento::State.first.reload.record_data.should eql(nil)
  end
  
  it "should create object" do
    Project.find_by_id(@project.id).should_not be_nil
    Project.count.should eql(1)
  end
  
  it "should allow rewinding/undoing the creation" do
    Memento::Session.last.rewind
    Project.count.should eql(0)
  end
  
  describe "when rewinding/undoing the creation" do
    it "should give back rewinded_object" do
      Memento::Session.last.rewind.map{|e| e.object.class }.should eql([Project])
    end

    it "should not rewind the creatio if object was modified" do
      Project.last.update_attribute(:created_at, 1.minute.ago)
      rewinded = Memento::Session.last.rewind
      Project.count.should eql(1)
      rewinded.first.should_not be_success
      rewinded.first.error.should be_was_changed
    end
    
    describe "when record was already destroyed" do
      
      it "should give back fake unsaved record with id set" do
        Project.last.destroy
        @rewinded = Memento::Session.last.rewind
        @rewinded.size.should eql(1)
        @rewinded.first.object.should be_kind_of(Project)
        @rewinded.first.object.id.should eql(@project.id)
        @rewinded.first.object.name.should be_nil
        @rewinded.first.object.should be_new_record
        Project.count.should eql(0)
      end
    
      it "should give back fake unsaved record with all data set when destruction was stateed" do
        Memento.instance.recording(@user) { Project.last.destroy }
        Memento::State.last.update_attribute(:created_at, 5.minutes.from_now)
        @rewinded = Memento::Session.first.rewind
        @rewinded.size.should eql(1)
        @rewinded.first.object.should be_kind_of(Project)
        @rewinded.first.object.id.should eql(@project.id)
        @rewinded.first.object.name.should eql(@project.name)
        @rewinded.first.object.closed_at.should eql(@project.closed_at)
        @rewinded.first.object.should be_new_record
        Project.count.should eql(0)
      end
    end
  end
  
  
  
end