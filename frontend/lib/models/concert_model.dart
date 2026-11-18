class ConcertModel {
  final int concertId;
  final String title;
  final String? artist;
  final String? category;
  final String? description;
  final String venue;
  final String showDatetime;
  final String? posterUrl;

  const ConcertModel({
    required this.concertId,
    required this.title,
    this.artist,
    this.category,
    this.description,
    required this.venue,
    required this.showDatetime,
    this.posterUrl,
  });

  factory ConcertModel.fromJson(Map<String, dynamic> json) {
    return ConcertModel(
      concertId: (json['concert_id'] ?? 0) as int,
      title: (json['title'] ?? json['name'] ?? '').toString(),
      artist: json['artist']?.toString(),
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      venue: (json['venue'] ?? json['location'] ?? '').toString(),
      showDatetime: (json['show_datetime'] ?? json['date'] ?? '').toString(),
      posterUrl: (json['poster_url'] ?? json['image'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'concert_id': concertId,
      'title': title,
      'artist': artist,
      'category': category,
      'description': description,
      'venue': venue,
      'show_datetime': showDatetime,
      'poster_url': posterUrl,
    };
  }
}
