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
        ..text = DEMO_GENDER
        ..tagId = 'tag-0102'
        ..type = TagType.Normal
        ..shortcut = 'g',
    DEMO_AGE: new Tag()
        ..text = DEMO_AGE
        ..tagId = 'tag-7012'
        ..type = TagType.Normal
        ..shortcut = 'a',
    DEMO_LOCATION: new Tag()
        ..text = DEMO_LOCATION
        ..tagId = 'tag-5812'
        ..type = TagType.Normal
        ..shortcut = 'l',

    WATER_QUALITY: new Tag()
        ..text = WATER_QUALITY
        ..tagId = 'tag-ashk'
        ..type = TagType.Normal
        ..shortcut = 'q',
    HEALTHCARE: new Tag()
        ..text = HEALTHCARE
        ..tagId = 'tag-alsf'
        ..type = TagType.Normal
        ..shortcut = 'h',
    RELIGION: new Tag()
        ..text = RELIGION
        ..tagId = 'tag-ahsx'
        ..type = TagType.Normal
        ..shortcut = 'r',
    WEATHER: new Tag()
        ..text = WEATHER
        ..tagId = 'tag-ahos'
        ..type = TagType.Normal
        ..shortcut = 'w',

    CLEAN_WATER_ACCESS: new Tag()
        ..text = CLEAN_WATER_ACCESS
        ..tagId = 'tag-blas'
        ..type = TagType.Normal
        ..shortcut = 'c',
    NO_CLEAN_WATER_ACCESS: new Tag()
        ..text = NO_CLEAN_WATER_ACCESS
        ..tagId = 'tag-boda'
        ..type = TagType.Important
        ..shortcut = 'n',
  };

List<Conversation> _conversations = [
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'ahsoasgoqbalhaisdyoa'
        ..shortValue = 'ahso-asgo-qbal')
    ..demographicsInfo = {'Gender': 'Female', 'Age': '28', 'Location':'East'}
    ..tags = [_tags[NO_CLEAN_WATER_ACCESS]]
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'Yes. because of poor water quality'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 7))
        ..tags = [_tags[WATER_QUALITY]],
      new Message()
        ..direction = MessageDirection.Out
        ..text = 'Thanks for your message. How old are you?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..text = '28'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_AGE]],
      new Message()
        ..direction = MessageDirection.Out
        ..text = 'What\'s your gender?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..text = 'Female'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_GENDER]],
      new Message()
        ..direction = MessageDirection.Out
        ..text = 'Which area do you live in?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..text = 'East'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_LOCATION]],
      new Message()
        ..direction = MessageDirection.Out
        ..text = 'Thanks for your messages. Do you have access to clean water now?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..text = 'No, I have to buy it every week'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 5))
        ..tags = [_tags[NO_CLEAN_WATER_ACCESS]],
      new Message()
        ..direction = MessageDirection.Out
        ..text = 'How much do you have to pay for it'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 4))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..text = '50 cents per litre, I can manage, and hopefully it won\'t be for too long'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 3))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'glarbglspaxbhaslasoa'
        ..shortValue = 'glar-bgls-paxb')
    ..demographicsInfo = {'Gender': 'Male', 'Age': '16', 'Location':'East'}
    ..tags = [_tags[CLEAN_WATER_ACCESS]]
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'Yes because people drink dirty water'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 7))
        ..tags = [_tags[WATER_QUALITY]],
      new Message()
        ..direction = MessageDirection.Out
        ..text = 'Thanks for your message. How old are you?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..text = '16'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_AGE]],
      new Message()
        ..direction = MessageDirection.Out
        ..text = 'What\'s your gender?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..text = 'Male'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_GENDER]],
      new Message()
        ..direction = MessageDirection.Out
        ..text = 'Which area do you live in?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..text = 'East'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_LOCATION]],
      new Message()
        ..direction = MessageDirection.Out
        ..text = 'Thanks for your messages. Do you have access to clean water now?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..text = 'Yes I use a filter to clean water from the village well'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 5))
        ..tags = [_tags[CLEAN_WATER_ACCESS]],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'alhapcaavasscgbeygjh'
        ..shortValue = 'alha-pcaa-vass')
    ..demographicsInfo = {'Gender': 'Female', 'Age': '46', 'Location':'West'}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'There is enough hospitals in the area'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [_tags[HEALTHCARE]],
      new Message()
        ..direction = MessageDirection.Out
        ..text = 'Thanks for your message. How old are you?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..text = '46'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_AGE]],
      new Message()
        ..direction = MessageDirection.Out
        ..text = 'What\'s your gender?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..text = 'Female'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_GENDER]],
      new Message()
        ..direction = MessageDirection.Out
        ..text = 'Which area do you live in?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
      new Message()
        ..direction = MessageDirection.In
        ..text = 'West'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [_tags[DEMO_LOCATION]],
      new Message()
        ..direction = MessageDirection.Out
        ..text = 'Thanks for your messages. Do you have access to clean water now?'
        ..datetime = new DateTime.now().subtract(new Duration(days: 2, hours: 6))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'agsoashkchlsaksjdgos'
        ..shortValue = 'agso-ashk-chls')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'The people of the area work on the cleanliness of the town and accessing clean water'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ]
    ..notes = 'Can someone translate this message please',
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'ahlscnhlflascjakiwac'
        ..shortValue = 'ahls-cnhl-flas')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'Yes because our people don\'t take good care of sewages and dirt'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'jalablasohsabckalgdk'
        ..shortValue = 'jala-blas-ohsa')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'No because the health workers have done great job in creating awareness'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'ahlsbxksmahsblpqhdfa'
        ..shortValue = 'ahls-bxks-mahs')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'No because we are people who are connected to their God'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'bladqhlavblahlqzblhx'
        ..shortValue = 'blad-qhla-zblh')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'No proper sanitation in that the boreholes and toilets are close to each other'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'ashabckayljablskalsh'
        ..shortValue = 'asha-bcka-ylja')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'People especially those living far from towns lack awawreness'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'ghlaghjlyuioflalskbm'
        ..shortValue = 'ghla-ghjl-yuio')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'Because of the garbage all over the town'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'halsashkwerjfglaskla'
        ..shortValue = 'hals-ashk-werj')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'No because this disease is not so common in Somalia'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'mnbxvbnmdfhglqnvldgh'
        ..shortValue = 'mnbx-vbnm-dfgh')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'There is influx of internally displaced peronss intowns nowadays and do not have propersanitation'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'dfghjhgasdfgclasolap'
        ..shortValue = 'dfgh-jhga-sdfg')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'There is no free access to free medical care facilities'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'ertypoiuwerjglqadsal'
        ..shortValue = 'erty-poiu-werj')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'No Because Allah is enough for us and we ask him to protect us from this disease'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'oiuyhjkljhgfvblaskal'
        ..shortValue = 'oiuy-hjkl-jhgf')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'our government is not providing sanitation'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'lklkhkjkupoqgvfhladl'
        ..shortValue = 'lklk-hkjk-upoq')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'yes it is hot and dry'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'dfuaagskslkdweqylfhs'
        ..shortValue = 'dfua-agsk-slkd')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'yes because it spreads through contaminated water'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'ooiwppqphlkkgvalsika'
        ..shortValue = 'ooiw-ppqp-hlkk')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'no because none of my friends have it'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
  new Conversation()
    ..deidentifiedPhoneNumber = (
      new DeidentifiedPhoneNumber()
        ..value = 'zbvxzxccbvxmvoqipwqp'
        ..shortValue = 'zbvx-zxcc-bvxm')
    ..demographicsInfo = {}
    ..tags = []
    ..messages = [
      new Message()
        ..direction = MessageDirection.In
        ..text = 'yes,my neighbour is very sick.'
        ..datetime = new DateTime.now().subtract(new Duration(days: 3, hours: 7))
        ..tags = [],
    ],
];

List<SuggestedReply> _suggestedReplies = [
  new SuggestedReply()
    ..text = 'Thanks for your message. How old are you?'
    ..shortcut = '1',
  new SuggestedReply()
    ..text = 'What\'s your gender?'
    ..shortcut = '2',
  new SuggestedReply()
    ..text = 'Which area do you live in?'
    ..shortcut = '3',
  new SuggestedReply()
    ..text = 'Thanks for your messages. Do you have access to clean water now?'
    ..shortcut = '4',
  new SuggestedReply()
    ..text = 'How much do you have to pay for it?'
    ..shortcut = '5',
];

List<Tag> get messageTags => _tags.values.toList();
List<Tag> get conversationTags {
  Map<String, Tag> tagsCopy = new Map<String, Tag>.from(_tags);
  tagsCopy.removeWhere((key, tag) => [DEMO_AGE, DEMO_GENDER, DEMO_LOCATION].contains(key));
  return tagsCopy.values.toList();
}

List<SuggestedReply> get suggestedReplies => _suggestedReplies;

List<Conversation> get conversations => _conversations;
