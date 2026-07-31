import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartrideug/core/services/transit_repository.dart';
import 'package:smartrideug/features/home/booking_confirmed_page.dart';

/// A local-only payment screen used to exercise the full booking lifecycle.
/// It never contacts MTN or moves real money.
class MomoPaymentPage extends StatefulWidget {
  const MomoPaymentPage({
    super.key,
    required this.bookingId,
    required this.fare,
    required this.expiresAt,
  });

  final String bookingId;
  final int fare;
  final DateTime expiresAt;

  @override
  State<MomoPaymentPage> createState() => _MomoPaymentPageState();
}

class _MomoPaymentPageState extends State<MomoPaymentPage> {
  final _phone = TextEditingController(text: '0770 000 000');
  Timer? _timer;
  bool _processing = false;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _loadDefaultMomoNumber();
  }

  Future<void> _loadDefaultMomoNumber() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final methods = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('paymentMethods')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    if (!mounted || methods.docs.isEmpty) return;
    final phone = methods.docs.first.data()['phone']?.toString().trim();
    if (phone?.isNotEmpty == true) _phone.text = phone!;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    super.dispose();
  }

  void _tick() {
    final remaining = widget.expiresAt.difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) {
      _timer?.cancel();
      TransitRepository().expireBooking(widget.bookingId);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (mounted) setState(() => _remaining = remaining);
  }

  Future<void> _pay() async {
    if (_processing) return;
    if (_phone.text.replaceAll(RegExp(r'\D'), '').length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid MTN mobile number.')),
      );
      return;
    }
    setState(() => _processing = true);
    try {
      // Deliberate simulated approval delay; no external payment API is used.
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!widget.expiresAt.isAfter(DateTime.now())) {
        await TransitRepository().expireBooking(widget.bookingId);
        throw StateError('The two-minute confirmation window has expired.');
      }
      final stamp = DateTime.now().millisecondsSinceEpoch;
      await TransitRepository().confirmBooking(
        widget.bookingId,
        paymentReference: 'MOMO-SIM-$stamp',
        ticketToken: 'SR-${widget.bookingId}-$stamp',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingConfirmedPage(bookingId: widget.bookingId),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _remaining.isNegative ? 0 : _remaining.inSeconds;
    final timerLabel =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: const Text('MTN MoMo payment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Simulation only — no real MTN MoMo payment will be made.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),
            const Icon(
              Icons.account_balance_wallet,
              size: 72,
              color: Color(0xFFFFC107),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pay with MTN MoMo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'UGX ${widget.fare}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'MTN mobile number',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Complete payment within $timerLabel',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _processing ? null : _pay,
                icon: _processing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open),
                label: Text(
                  _processing
                      ? 'Approving simulated payment…'
                      : 'Simulate payment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
