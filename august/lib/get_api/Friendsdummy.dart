class DataModel {
  static int _idCounter = 0; // static 변수로 클래스 레벨에서 id 카운터를 관리
  final String title;
  final String imageName;
  final String subtitle;
  final int id;

  DataModel(
    this.title,
    this.imageName,
    this.subtitle,
  ) : this.id = ++_idCounter; // 생성자에서 id를 자동으로 할당
}

List<DataModel> dataList = [
  // DataModel("Beta", "assets/icons/memoji.png", "Freshman"),
  // DataModel("Alpha", "assets/icons/memoji.png", "Freshman"),
  // DataModel("Gamma", "assets/icons/memoji.png", "Freshman"),
  // DataModel("Beta", "assets/icons/memoji.png", "Freshman"),
  // DataModel("Alpha", "assets/icons/memoji.png", "Freshman"),
  // DataModel("Gamma", "assets/icons/memoji.png", "Freshman"),
  // DataModel("Beta", "assets/icons/memoji.png", "Freshman"),
  // DataModel("Alpha", "assets/icons/memoji.png", "Freshman"),
  // DataModel("Gamma", "assets/icons/memoji.png", "Freshman"),
  // DataModel("Beta", "assets/icons/memoji.png", "Freshman"),
  // DataModel("Alpha", "assets/icons/memoji.png", "Freshman"),
  // DataModel("Gamma", "assets/icons/memoji.png", "Freshman"),
];
