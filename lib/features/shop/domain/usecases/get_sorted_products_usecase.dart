import 'package:dartz/dartz.dart';
import 'package:utmmart/core/utils/exceptions/exceptions.dart';
import 'package:utmmart/features/shop/domain/entities/product_entity.dart';
import 'package:utmmart/features/shop/domain/repository/shop_repository.dart';

class GetSortedProductsUsecase {
  final ShopRepository shopRepository;

  GetSortedProductsUsecase({required this.shopRepository});

  Future<Either<TExceptions, List<ProductEntity>>> call(
      {required String sortBy, required String sortType}) async {
    return await shopRepository.getSortedProducts(
        sortBy: sortBy, sortType: sortType);
  }
}
