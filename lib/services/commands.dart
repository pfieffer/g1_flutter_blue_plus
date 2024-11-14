enum Command {
  START_AI(0xF5),
  OPEN_MIC(0x0E),
  MIC_RESPONSE(0x0E),
  RECEIVE_MIC_DATA(0xF1),
  INIT(0x4D),
  HEARTBEAT(0x25),
  SEND_RESULT(0x4E),
  QUICK_NOTE(0x21),
  DASHBOARD(0x22),
  NOTIFICATION(0x4B);

  final int value;
  const Command(this.value);
}

class SendResult {
  final Command command;
  final int seq;
  final int totalPackages;
  final int currentPackage;
  final int screenStatus;
  final int newCharPos0;
  final int newCharPos1;
  final int pageNumber;
  final int maxPages;
  final List<int> data;

  SendResult({
    required this.command,
    this.seq = 0,
    this.totalPackages = 1,
    this.currentPackage = 0,
    this.screenStatus = 0x31, // Example value
    this.newCharPos0 = 0,
    this.newCharPos1 = 0,
    this.pageNumber = 1,
    this.maxPages = 1,
    required this.data,
  });

  List<int> build() {
    return [
      command.value,
      seq & 0xFF,
      totalPackages & 0xFF,
      currentPackage & 0xFF,
      screenStatus & 0xFF,
      newCharPos0 & 0xFF,
      newCharPos1 & 0xFF,
      pageNumber & 0xFF,
      maxPages & 0xFF,
      ...data,
    ];
  }
}

List<int> constructHeartbeat(int seq) {
  int length = 6;
  return [
    Command.HEARTBEAT.value,
    length & 0xFF,
    (length >> 8) & 0xFF,
    seq % 0xFF,
    0x04,
    seq % 0xFF,
  ];
}