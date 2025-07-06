import 'package:dartz/dartz.dart';
import 'package:utmmart/core/utils/exceptions/exceptions.dart';
import 'package:utmmart/features/shop/domain/entities/product_entity.dart';
import 'package:utmmart/features/shop/domain/repository/shop_repository.dart';

class GetProductByIdUsecase {
  final ShopRepository shopRepository;

  GetProductByIdUsecase({required this.shopRepository});

  Future<Either<TExceptions, ProductEntity>> call({required int productId}) async {
    return await shopRepository.getProductById(productId: productId);
  }
}
