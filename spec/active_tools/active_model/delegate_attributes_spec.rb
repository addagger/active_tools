require 'spec_helper'

describe ActiveTools::ActiveModel::DelegateAttributes do
  class Parent
    include ActiveModel::Validations
    include ActiveTools::ActiveModel::DelegateAttributes

    attr_accessor :child

    delegate_attributes :name, to: :child, writer: true
    delegate_attributes :name, to: :child, prefix: :prefixed, writer: true
  end

  class Child
    include ActiveModel::Validations
    include ActiveTools::ActiveModel::DelegateAttributes

    attr_accessor :name

    validates_presence_of :name
  end

  let(:teh_object) { Parent.new.tap{|parent| parent.child = teh_child} }
  let(:teh_child) { Child.new }

  it "delegates the given attribute from parent to child" do
    teh_object.name = "Foo"

    expect(teh_child.name).to eq("Foo")
    expect(teh_object.name).to eq("Foo")
  end

  it "delegates the given attribute with a prefix from parent to child" do
    teh_object.prefixed_name = "Bar"

    expect(teh_child.name).to eq("Bar")
    expect(teh_object.prefixed_name).to eq("Bar")
  end

  it "forwards the errors from child to parent" do
    expect(teh_object.valid?).to be_false
    expect(teh_object.errors.messages[:name]).to eq(["can't be blank"])
  end

  it "forwards the errors from child to parent via prefix" do
    expect(teh_object.valid?).to be_false
    expect(teh_object.errors.messages[:prefixed_name]).to eq(["can't be blank"])
  end
end
