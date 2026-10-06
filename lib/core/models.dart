import 'json.dart';

class OrderStatus {
  static const String assigned = 'ASSIGNED';
  static const String outForDelivery = 'OUT_FOR_DELIVERY';
  static const String delivered = 'DELIVERED';
  static const String cancelled = 'CANCELLED';
}

class Place {
  const Place({this.id, this.name = '', this.address = '', this.phone = '', this.city = '', this.lat, this.lng});

  final int? id;
  final String name;
  final String address;
  final String phone;
  final String city;
  final double? lat;
  final double? lng;

  bool get hasLocation => lat != null && lng != null;

  factory Place.fromJson(dynamic j) {
    final m = asMap(j);
    return Place(
      id: asInt(m['id']),
      name: asString(m['name']),
      address: asString(m['address']),
      phone: asString(m['phone']),
      city: asString(m['city']),
      lat: asDouble(m['lat']),
      lng: asDouble(m['lng']),
    );
  }
}

class Rider {
  const Rider({
    required this.id,
    this.code = '',
    this.empId = '',
    this.name = '',
    this.phone = '',
    this.username = '',
    this.password = '',
    this.joined,
    this.status = '',
    this.unread = 0,
    this.onDuty = false,
    this.onDutyAt,
    this.deliveryStatus = '',
    this.openOrders = 0,
    this.shop,
  });

  final int id;
  final String code;
  final String empId;
  final String name;
  final String phone;
  final String username;
  final String password;
  final DateTime? joined;
  final String status;
  final int unread;
  final bool onDuty;
  final DateTime? onDutyAt;
  final String deliveryStatus;
  final int openOrders;
  final Place? shop;

  factory Rider.fromJson(dynamic j) {
    final m = asMap(j);
    return Rider(
      id: asInt(m['id']) ?? 0,
      code: asString(m['code']),
      empId: asString(m['emp_id']),
      name: asString(m['name']),
      phone: asString(m['phone']),
      username: asString(m['username']),
      password: asString(m['password']),
      joined: asDate(m['joined']),
      status: asString(m['status']),
      unread: asInt(m['unread']) ?? 0,
      onDuty: m['on_duty'] == true,
      onDutyAt: asDate(m['on_duty_at']),
      deliveryStatus: asString(m['delivery_status']),
      openOrders: asInt(m['open_orders']) ?? 0,
      shop: m['shop'] is Map ? Place.fromJson(m['shop']) : null,
    );
  }
}

class OrderItem {
  const OrderItem({this.name = '', this.qty = 0, this.price = 0, this.total = 0});

  final String name;
  final int qty;
  final double price;
  final double total;

  factory OrderItem.fromJson(dynamic j) {
    final m = asMap(j);
    return OrderItem(
      name: asString(m['name']),
      qty: asInt(m['qty']) ?? 0,
      price: asDouble(m['price']) ?? 0,
      total: asDouble(m['total']) ?? 0,
    );
  }
}

class RiderOrder {
  const RiderOrder({
    required this.id,
    required this.code,
    required this.status,
    this.statusLabel = '',
    this.channel = '',
    this.paymentType = '',
    this.paymentLabel = '',
    this.subtotal = 0,
    this.fee = 0,
    this.discount = 0,
    this.total = 0,
    this.remarks = '',
    this.createdAt,
    this.assignedAt,
    this.dispatchedAt,
    this.arrivedAt,
    this.deliveredAt,
    this.updatedAt,
    this.distanceKm,
    this.actualKm,
    this.deliveryMin,
    this.cancelReason = '',
    this.cancelledAt,
    this.cancelledVia = '',
    this.cancelledBy = '',
    this.route,
    this.customer = const Place(),
    this.shop = const Place(),
    this.items = const <OrderItem>[],
  });

  final int id;
  final String code;
  final String status;
  final String statusLabel;
  final String channel;
  final String paymentType;
  final String paymentLabel;
  final double subtotal;
  final double fee;
  final double discount;
  final double total;
  final String remarks;
  final DateTime? createdAt;
  final DateTime? assignedAt;
  final DateTime? dispatchedAt;
  final DateTime? arrivedAt;
  final DateTime? deliveredAt;
  final DateTime? updatedAt;
  final double? distanceKm;
  final double? actualKm;
  final int? deliveryMin;
  final String cancelReason;
  final DateTime? cancelledAt;
  final String cancelledVia;
  final String cancelledBy;
  final String? route;
  final Place customer;
  final Place shop;
  final List<OrderItem> items;

  bool get isAssigned => status == OrderStatus.assigned;
  bool get isOut => status == OrderStatus.outForDelivery;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isActive => isAssigned || isOut;
  bool get cancelledByMe => cancelledBy.toLowerCase() == 'you';

  double? get km {
    final a = actualKm;
    if (isDelivered && a != null && a > 0) return a;
    final d = distanceKm;
    if (d != null && d > 0) return d;
    return a != null && a > 0 ? a : null;
  }

  DateTime? get finishedAt => deliveredAt ?? cancelledAt ?? updatedAt ?? createdAt;

  String get paymentShort {
    final t = paymentType.toUpperCase();
    if (t == 'COD' || t == 'CASH') return 'Cash';
    if (t == 'CARD') return 'Card';
    return paymentLabel.isEmpty ? paymentType : paymentLabel;
  }

  factory RiderOrder.fromJson(dynamic j) {
    final m = asMap(j);
    final route = asString(m['route']);
    return RiderOrder(
      id: asInt(m['id']) ?? 0,
      code: asString(m['code']),
      status: asString(m['status']),
      statusLabel: asString(m['status_label']),
      channel: asString(m['channel']),
      paymentType: asString(m['payment_type']),
      paymentLabel: asString(m['payment_label']),
      subtotal: asDouble(m['subtotal']) ?? 0,
      fee: asDouble(m['fee']) ?? 0,
      discount: asDouble(m['discount']) ?? 0,
      total: asDouble(m['total']) ?? 0,
      remarks: asString(m['remarks']),
      createdAt: asDate(m['created_at']),
      assignedAt: asDate(m['assigned_at']),
      dispatchedAt: asDate(m['dispatched_at']),
      arrivedAt: asDate(m['arrived_at']),
      deliveredAt: asDate(m['delivered_at']),
      updatedAt: asDate(m['updated_at']),
      distanceKm: asDouble(m['distance_km']),
      actualKm: asDouble(m['actual_km']),
      deliveryMin: asInt(m['delivery_min']),
      cancelReason: asString(m['cancel_reason']),
      cancelledAt: asDate(m['cancelled_at']),
      cancelledVia: asString(m['cancelled_via']),
      cancelledBy: asString(m['cancelled_by']),
      route: route.isEmpty ? null : route,
      customer: Place.fromJson(m['customer']),
      shop: Place.fromJson(m['shop']),
      items: asList(m['items']).map(OrderItem.fromJson).toList(),
    );
  }
}

class StatusCounts {
  const StatusCounts({this.all = 0, this.assigned = 0, this.outForDelivery = 0, this.delivered = 0, this.cancelled = 0});

  final int all;
  final int assigned;
  final int outForDelivery;
  final int delivered;
  final int cancelled;

  int get active => assigned + outForDelivery;

  int of(String filter) {
    switch (filter) {
      case OrderStatus.assigned:
        return assigned;
      case OrderStatus.outForDelivery:
        return outForDelivery;
      case OrderStatus.delivered:
        return delivered;
      case OrderStatus.cancelled:
        return cancelled;
      default:
        return all;
    }
  }

  factory StatusCounts.fromJson(dynamic j) {
    final m = asMap(j);
    final assigned = asInt(m['assigned']) ?? 0;
    final out = asInt(m['out_for_delivery']) ?? 0;
    final delivered = asInt(m['delivered']) ?? 0;
    final cancelled = asInt(m['cancelled']) ?? 0;
    return StatusCounts(
      all: asInt(m['all']) ?? asInt(m['total']) ?? (assigned + out + delivered + cancelled),
      assigned: assigned,
      outForDelivery: out,
      delivered: delivered,
      cancelled: cancelled,
    );
  }
}

class TodayOrders {
  const TodayOrders({this.counts = const StatusCounts(), this.rows = const <RiderOrder>[]});

  final StatusCounts counts;
  final List<RiderOrder> rows;

  factory TodayOrders.fromJson(dynamic j) {
    final m = asMap(j);
    return TodayOrders(
      counts: StatusCounts.fromJson(m['counts']),
      rows: asList(m['rows']).map(RiderOrder.fromJson).toList(),
    );
  }
}

class WeekDay {
  const WeekDay({required this.day, this.delivered = 0});

  final String day;
  final int delivered;

  factory WeekDay.fromJson(dynamic j) {
    final m = asMap(j);
    return WeekDay(day: asString(m['day']), delivered: asInt(m['delivered']) ?? 0);
  }
}

class HomeStats {
  const HomeStats({
    this.today = '',
    this.counts = const StatusCounts(),
    this.distanceKm = 0,
    this.avgDeliveryMin,
    this.onDutyMin = 0,
    this.week = const <WeekDay>[],
    this.weekTotal = 0,
  });

  final String today;
  final StatusCounts counts;
  final double distanceKm;
  final int? avgDeliveryMin;
  final int onDutyMin;
  final List<WeekDay> week;
  final int weekTotal;

  factory HomeStats.fromJson(dynamic j) {
    final m = asMap(j);
    return HomeStats(
      today: asString(m['today']),
      counts: StatusCounts.fromJson(m['counts']),
      distanceKm: asDouble(m['distance_km']) ?? 0,
      avgDeliveryMin: asInt(m['avg_delivery_min']),
      onDutyMin: asInt(m['on_duty_min']) ?? 0,
      week: asList(m['week']).map(WeekDay.fromJson).toList(),
      weekTotal: asInt(m['week_total']) ?? 0,
    );
  }
}

class HistorySummary {
  const HistorySummary({this.delivered = 0, this.cancelled = 0, this.amount = 0, this.km = 0, this.avgDeliveryMin});

  final int delivered;
  final int cancelled;
  final double amount;
  final double km;
  final int? avgDeliveryMin;

  factory HistorySummary.fromJson(dynamic j) {
    final m = asMap(j);
    return HistorySummary(
      delivered: asInt(m['delivered']) ?? 0,
      cancelled: asInt(m['cancelled']) ?? 0,
      amount: asDouble(m['amount']) ?? 0,
      km: asDouble(m['km']) ?? 0,
      avgDeliveryMin: asInt(m['avg_delivery_min']),
    );
  }
}

class HistoryPage {
  const HistoryPage({
    this.page = 1,
    this.pages = 1,
    this.total = 0,
    this.summary = const HistorySummary(),
    this.rows = const <RiderOrder>[],
  });

  final int page;
  final int pages;
  final int total;
  final HistorySummary summary;
  final List<RiderOrder> rows;

  factory HistoryPage.fromJson(dynamic j) {
    final m = asMap(j);
    return HistoryPage(
      page: asInt(m['page']) ?? 1,
      pages: asInt(m['pages']) ?? 1,
      total: asInt(m['total']) ?? 0,
      summary: HistorySummary.fromJson(m['summary']),
      rows: asList(m['rows']).map(RiderOrder.fromJson).toList(),
    );
  }
}

class RiderNotification {
  const RiderNotification({
    required this.id,
    this.kind = '',
    this.title = '',
    this.body = '',
    this.orderId,
    this.readAt,
    this.createdAt,
  });

  final int id;
  final String kind;
  final String title;
  final String body;
  final int? orderId;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get unread => readAt == null;

  RiderNotification markRead() => RiderNotification(
        id: id,
        kind: kind,
        title: title,
        body: body,
        orderId: orderId,
        readAt: readAt ?? DateTime.now(),
        createdAt: createdAt,
      );

  factory RiderNotification.fromJson(dynamic j) {
    final m = asMap(j);
    return RiderNotification(
      id: asInt(m['id']) ?? 0,
      kind: asString(m['kind']),
      title: asString(m['title']),
      body: asString(m['body']),
      orderId: asInt(m['order_id']),
      readAt: asDate(m['read_at']),
      createdAt: asDate(m['created_at']),
    );
  }
}

class NotificationPage {
  const NotificationPage({this.page = 1, this.pages = 1, this.total = 0, this.unread = 0, this.rows = const <RiderNotification>[]});

  final int page;
  final int pages;
  final int total;
  final int unread;
  final List<RiderNotification> rows;

  factory NotificationPage.fromJson(dynamic j) {
    final m = asMap(j);
    return NotificationPage(
      page: asInt(m['page']) ?? 1,
      pages: asInt(m['pages']) ?? 1,
      total: asInt(m['total']) ?? 0,
      unread: asInt(m['unread']) ?? 0,
      rows: asList(m['rows']).map(RiderNotification.fromJson).toList(),
    );
  }
}

class ShopRoute {
  const ShopRoute({this.name = '', this.navigateUrl = '', this.lat, this.lng});

  final String name;
  final String navigateUrl;
  final double? lat;
  final double? lng;

  factory ShopRoute.fromJson(dynamic j) {
    final m = asMap(j);
    return ShopRoute(
      name: asString(m['name']),
      navigateUrl: asString(m['navigate_url']),
      lat: asDouble(m['lat']),
      lng: asDouble(m['lng']),
    );
  }
}

class ActionResult {
  const ActionResult(this.ok, this.message);

  final bool ok;
  final String message;
}
