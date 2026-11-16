import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/cart_provider.dart';

class BadgeCartIcon extends StatelessWidget {
  final VoidCallback onTap;

  const BadgeCartIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final count = cart.itemCount;

    return IconButton(
      onPressed: onTap,
      icon: count > 0
          ? badges.Badge(
              badgeContent: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.red,
                padding: EdgeInsets.all(4),
              ),
              child: const Icon(Icons.shopping_cart_outlined),
            )
          : const Icon(Icons.shopping_cart_outlined),
      tooltip: 'Keranjang',
    );
  }
}
