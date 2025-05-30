import 'package:fpdart/fpdart.dart';

import '../error/error.dart';

abstract class UseCase<Right, Param extends Params> {
  const UseCase();

  Future<Either<AppError, Right>> call(Param params);
}

final class NoParams extends Params {
  const NoParams();
}

abstract class Params {
  const Params();
}
