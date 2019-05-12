import 'model.dart';

const DEMO_GENDER = 'gender';
const DEMO_AGE = 'age';
const DEMO_LOCATION = 'location';

const WATER_QUALITY = 'water_quality';
const HEALTHCARE = 'healthcare';
const RELIGION = 'religion';
const WEATHER = 'weather';

const CLEAN_WATER_ACCESS = 'clean_water_access';
const NO_CLEAN_WATER_ACCESS = 'no_clean_water_access';


Map<String, Tag> _tags = {
    DEMO_GENDER: new Tag()
        ..content = DEMO_GENDER
        ..tagId = 'tag-0102'
        ..type = TagType.Normal,
    DEMO_AGE: new Tag()
        ..content = DEMO_AGE
        ..tagId = 'tag-7012'
        ..type = TagType.Normal,
    DEMO_LOCATION: new Tag()
        ..content = DEMO_LOCATION
        ..tagId = 'tag-5812'
        ..type = TagType.Normal,

    WATER_QUALITY: new Tag()
        ..content = WATER_QUALITY
        ..tagId = 'tag-ashk'
        ..type = TagType.Normal,
    HEALTHCARE: new Tag()
        ..content = HEALTHCARE
        ..tagId = 'tag-alsf'
        ..type = TagType.Normal,
    RELIGION: new Tag()
        ..content = RELIGION
        ..tagId = 'tag-ahsx'
        ..type = TagType.Normal,
    WEATHER: new Tag()
        ..content = WEATHER
        ..tagId = 'tag-ahos'
        ..type = TagType.Normal,

    CLEAN_WATER_ACCESS: new Tag()
        ..content = CLEAN_WATER_ACCESS
        ..tagId = 'tag-blas'
        ..type = TagType.Normal,
    NO_CLEAN_WATER_ACCESS: new Tag()
        ..content = NO_CLEAN_WATER_ACCESS
        ..tagId = 'tag-boda'
        ..type = TagType.Important,
  };

List<Conversation> _conversations = [
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'ahso-asgo-qbal')
    ..demographicsInfo = {'Gender': 'Female', 'Age': '28', 'Location':'East'}
    ..tags = [_tags[NO_CLEAN_WATER_ACCESS]]
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'Yes. because of poor water quality'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 7))
        ..tags = [_tags[WATER_QUALITY]],
      new Message()
        ..direction = MessageDirection.Out
        ..content = 'Thanks for your message. How old are you?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..content = '28'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_AGE]],
      new Message()
        ..direction = MessageDirection.Out
        ..content = 'What\'s your gender?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..content = 'Female'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_GENDER]],
      new Message()
        ..direction = MessageDirection.Out
        ..content = 'Which area do you live in?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..content = 'East'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_LOCATION]],
      new Message()
        ..direction = MessageDirection.Out
        ..content = 'Thanks for your messages. Do you have access to clean water now?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..content = 'No, I have to buy it every week'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 5))
        ..tags = [_tags[NO_CLEAN_WATER_ACCESS]],
      new Message()
        ..direction = MessageDirection.Out
        ..content = 'How much do you have to pay for it'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 4))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..content = '50 cents per litre, I can manage, and hopefully it won\'t be for too long'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 3))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'glar-bgls-paxb')
    ..demographicsInfo = {'Gender': 'Male', 'Age': '16', 'Location':'East'}
    ..tags = [_tags[CLEAN_WATER_ACCESS]]
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'Yes because people drink dirty water'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 7))
        ..tags = [_tags[WATER_QUALITY]],
      new Message()
        ..direction = MessageDirection.Out
        ..content = 'Thanks for your message. How old are you?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..content = '16'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_AGE]],
      new Message()
        ..direction = MessageDirection.Out
        ..content = 'What\'s your gender?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..content = 'Male'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_GENDER]],
      new Message()
        ..direction = MessageDirection.Out
        ..content = 'Which area do you live in?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..content = 'East'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_LOCATION]],
      new Message()
        ..direction = MessageDirection.Out
        ..content = 'Thanks for your messages. Do you have access to clean water now?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..content = 'Yes I use a filter to clean water from the village well'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 5))
        ..tags = [_tags[CLEAN_WATER_ACCESS]],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'alha-pcaa-vass')
    ..demographicsInfo = {'Gender': 'Female', 'Age': '46', 'Location':'West'}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'There is enough hospitals in the area'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [_tags[HEALTHCARE]],
      new Message()
        ..direction = MessageDirection.Out
        ..content = 'Thanks for your message. How old are you?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..content = '46'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_AGE]],
      new Message()
        ..direction = MessageDirection.Out
        ..content = 'What\'s your gender?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..content = 'Female'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_GENDER]],
      new Message()
        ..direction = MessageDirection.Out
        ..content = 'Which area do you live in?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..content = 'West'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_LOCATION]],
      new Message()
        ..direction = MessageDirection.Out
        ..content = 'Thanks for your messages. Do you have access to clean water now?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'agso-ashk-chls')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'The people of the area work on the cleanliness of the town and accessing clean water'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'ahls-cnhl-flas')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'Yes because our people don\'t take good care of sewages and dirt'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'jala-blas-ohsa')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'No because the health workers have done great job in creating awareness'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'ahls-bxks-mahs')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'No because we are people who are connected to their God'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'blad-qhla-zblh')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'No proper sanitation in that the boreholes and toilets are close to each other'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'asha-bcka-ylja')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'People especially those living far from towns lack awawreness'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'ghla-ghjl-yuio')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'Because of the garbage all over the town'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'hals-ashk-werj')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'No because this disease is not so common in Somalia'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'mnbx-vbnm-dfgh')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'There is influx of internally displaced peronss intowns nowadays and do not have propersanitation'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'dfgh-jhga-sdfg')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'There is no free access to free medical care facilities'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'erty-poiu-werj')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'No Because Allah is enough for us and we ask him to protect us from this disease'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'oiuy-hjkl-jhgf')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'our government is not providing sanitation'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'lklk-hkjk-upoq')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'yes it is hot and dry'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'dfua-agsk-slkd')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'yes because it spreads through contaminated water'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'ooiw-ppqp-hlkk')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'no because none of my friends have it'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (new DeidentifiedPhoneNumber()..shortValue = 'zbvx-zxcc-bvxm')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..content = 'yes,my neighbour is very sick.'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
];

List<Tag> get messageTags => _tags.values.toList();
List<Tag> get conversationTags {
  Map<String, Tag> tagsCopy = new Map<String, Tag>.from(_tags);
  tagsCopy.removeWhere((key, tag) => [DEMO_AGE, DEMO_GENDER, DEMO_LOCATION].contains(key));
  return tagsCopy.values.toList();

}

List<Conversation> get conversations => _conversations;
