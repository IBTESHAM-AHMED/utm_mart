import 'package:dartz/dartz.dart';
import 'package:utmmart/core/utils/exceptions/exceptions.dart';
import 'package:utmmart/features/shop/domain/entities/product_entity.dart';
import 'package:utmmart/features/shop/domain/repository/shop_repository.dart';

class GetProductsBySearchUsecase {
  final ShopRepository shopRepository;

  GetProductsBySearchUsecase({required this.shopRepository});

  Future<Either<TExceptions, List<ProductEntity>>> call(
      { String ?search=""}) async {
    return await shopRepository.getProductsBySearch(search: search);
  }
}
