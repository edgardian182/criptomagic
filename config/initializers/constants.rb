INTERVALS = {
  '1m' => 1,
  '3m' => 3,
  '5m' => 5,
  '15m' => 15,
  '30m' => 30,
  '1h' => 60,
  '2h' => 120,
  '4h' => 240,
  '6h' => 360,
  '8h' => 480,
  '12h' => 720,
  '1d' => 1440,
  '3d' => 4320,
  '1w' => 10_080,
  '1M' => 40_320
}.freeze

FLAG_DESCRIPTIONS = {
  'price_possible_divergence' => 'Detecta una posible divergencia por un aumento de precio a pesar de un volúmen bajo',
  'accumulated_price_divergence' => 'Detecta una posible divergencia en el precio teniendo en cuenta el volumen acumulado en las últimas velas',
  'hammer_hight' => 'Detecta la formación de una vela martillo',
  'volume_hight' => 'Detecta que ha habido un aumento de volúmen',
  'continuous_possible_price_up' => 'Detecta que han habido 3 velas seguidas con aumento de precio',
  'pump' => 'Detecta que ha habido un PUMP (aumento súbito del precio)',
  'dump' => 'Detecta que ha habido un DUMP (disminución súbita de precio)'
}.freeze
