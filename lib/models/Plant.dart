class Plant {
  String id;
  String name;
  String family;
  String scientificName;
  String image;
  String wateringType;
  bool indoor;

  Plant({
    required this.id,
    required this.name,
    required this.family,
    required this.scientificName,
    required this.image,
    required this.wateringType,
    required this.indoor,
  });

  factory Plant.fromMap(Map<String, dynamic> data) {
    return Plant(
      id: data['id'],
      name: data['name'],
      family: data['family'],
      scientificName: data['scientificName'],
      image: data['image'],
      wateringType: data['wateringType'],
      indoor: data['indoor'].toLowerCase() == 'true',
    );
  }
}
