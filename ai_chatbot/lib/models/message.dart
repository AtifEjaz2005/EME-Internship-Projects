class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});

  Map<String, dynamic> toJson() {
    return {"role": isUser ? "user" : "assistant", "content": text};
  }
}
