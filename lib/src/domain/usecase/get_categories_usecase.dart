import 'package:pick_my_snacks/src/data/model/get_category.dart';
import 'package:pick_my_snacks/src/domain/repository/category_repository.dart';

class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);
  final CategoryRepository _repository;
  Future<CategoryResponse> call() => _repository.getCategories();
}
