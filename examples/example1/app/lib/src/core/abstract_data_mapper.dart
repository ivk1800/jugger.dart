
abstract class AbstractDataMapper<IN, OUT> {

  const AbstractDataMapper();

  OUT transform(IN value);

  List<OUT> transformList(List<IN> value) {
    return value.map(transform).toList();
  }
}