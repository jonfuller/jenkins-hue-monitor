require_relative 'hue_monitor'

describe HueMonitor, "#execute" do
  before :each do
    @notifier = double('notifier')
    @monitor = HueMonitor.new @notifier
    @some_url = "http://url"
  end

  it "should call for passed if all builds are passing" do
    green = HueMonitor::colors[:passed]
    allow(@notifier).to receive(:get).and_return(passed_json)
    expect(@notifier).to receive(:put).with(/http/, /"hue":#{green}/, anything())
    @monitor.execute @some_url, @some_url
  end

  it "should call for failed_building if at least one build is building and one has failed" do
    failed_building = HueMonitor::colors[:failed_building]
    json = create_json [ :blue, :blue_anime, :red, :blue, :blue ]
    allow(@notifier).to receive(:get).and_return(json)
    expect(@notifier).to receive(:put).with(/http/, /"hue":#{failed_building}/, anything())
    @monitor.execute @some_url, @some_url
  end

  it "should call for failed_building if a failed build is building" do
    failed_building = HueMonitor::colors[:failed_building]
    allow(@notifier).to receive(:get).and_return(failed_building_json)
    expect(@notifier).to receive(:put).with(/http/, /{"hue":#{failed_building}/, anything())
    @monitor.execute @some_url, @some_url
  end

  it "should call for building if all are passing and at least one is building" do
    building = HueMonitor::colors[:building]
    allow(@notifier).to receive(:get).and_return(building_json)
    expect(@notifier).to receive(:put).with(/http/, /"hue":#{building}/, anything())
    @monitor.execute @some_url, @some_url
  end

  it "should call for failed if any are failing and none are building" do
    failed = HueMonitor::colors[:failed]
    allow(@notifier).to receive(:get).and_return(failed_json)
    expect(@notifier).to receive(:put).with(/http/, /"hue":#{failed}/, anything())
    @monitor.execute @some_url, @some_url
  end
end

describe HueMonitor, "color options" do
  before :each do
    @notifier = double('notifier')
    @some_url = "http://url"
  end

  it "allows to override failed color" do
    @monitor = HueMonitor.new(@notifier, {failed: 123})

    allow(@notifier).to receive(:get).and_return(failed_json)
    expect(@notifier).to receive(:put).with(/http/, /"hue":#{123}/, anything())

    @monitor.execute @some_url, @some_url
  end

  it "allows to override failed_building color" do
    @monitor = HueMonitor.new(@notifier, {failed_building: 456})

    allow(@notifier).to receive(:get).and_return(failed_building_json)
    expect(@notifier).to receive(:put).with(/http/, /{"hue":#{456}/, anything())

    @monitor.execute @some_url, @some_url
  end

  it "allows to override passed color" do
    @monitor = HueMonitor.new(@notifier, {passed: 789})

    allow(@notifier).to receive(:get).and_return(passed_json)
    expect(@notifier).to receive(:put).with(/http/, /"hue":#{789}/, anything())

    @monitor.execute @some_url, @some_url
  end

  it "allows to override building color" do
    @monitor = HueMonitor.new(@notifier, {building: 321})

    allow(@notifier).to receive(:get).and_return(building_json)
    expect(@notifier).to receive(:put).with(/http/, /"hue":#{321}/, anything())

    @monitor.execute @some_url, @some_url
  end

end

describe HueMonitor, "brightness" do
  before :each do
    @notifier = double('notifier')
    @some_url = "http://url"
  end

  it 'sets the brightness' do
    @monitor = HueMonitor.new(@notifier, nil, 20)

    allow(@notifier).to receive(:get).and_return(passed_json)
    expect(@notifier).to receive(:put).with(/http/, /"bri":#{20}/, anything())

    @monitor.execute @some_url, @some_url
  end
end

def passed_json
  create_json [ :blue, :blue, :blue, :blue, :blue ]
end

def failed_json
  create_json [ :blue, :blue, :blue, :red, :blue ]
end

def building_json
  create_json [ :blue, :blue_anime, :blue, :blue, :blue_anime ]
end

def failed_building_json
  create_json [ :blue, :red_anime, :blue, :blue, :blue ]
end

def create_json colors
  d = '"description":null'
  n = '"name":"builds"'
  p = '"property":[]'
  u = '"url":"http://jenkins/view/Builds/"'
  builds = colors.each_with_index.map do |color, index|
    b = "build%03d" % index
    c = color.to_s
    %Q({"name":"#{b}","url":"http://jenkins/job/#{b}/","color":"#{c}"})
  end

  %Q({#{d},"jobs":[#{builds.join ','}],#{n},#{p},#{u}})
end
