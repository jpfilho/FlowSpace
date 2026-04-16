import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import '../../config/azure_auth_config.dart';
import '../../features/auth/domain/data_providers.dart';

final GlobalKey<NavigatorState> _msGraphNavKey = GlobalKey<NavigatorState>();

class MSGraphService {
  late final AadOAuth _oauth;

  MSGraphService() {
    final config = Config(
      tenant: azureTenantId,
      clientId: azureClientId,
      scope: 'User.Read Calendars.Read Calendars.ReadWrite offline_access',
      redirectUri: azureRedirectUri,
      navigatorKey: _msGraphNavKey,
      webUseRedirect: true,
    );
    _oauth = AadOAuth(config);
  }

  Future<List<CalendarEventData>> fetchEvents(DateTime month) async {
    final hasCached = await _oauth.hasCachedAccountInformation;
    if (!hasCached) return [];

    final token = await _oauth.getAccessToken();
    if (token == null || token.isEmpty) return [];

    final start = DateTime(month.year, month.month - 1, 1).toIso8601String();
    final end = DateTime(month.year, month.month + 2, 0).toIso8601String();
    final url = Uri.parse('https://graph.microsoft.com/v1.0/me/calendarView?startDateTime=$start&endDateTime=$end&\$select=id,subject,bodyPreview,start,end,location,isAllDay,webLink');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Prefer': 'outlook.timezone="UTC"'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['value'] as List<dynamic>;

        return items.map((item) {
          final isAllDay = item['isAllDay'] as bool? ?? false;
          final dtStart = DateTime.parse(item['start']['dateTime'] as String).toLocal();
          final dtEnd = DateTime.parse(item['end']['dateTime'] as String).toLocal();

          return CalendarEventData(
            id: item['id'] as String,
            title: item['subject'] as String? ?? 'Evento Teams',
            description: (item['bodyPreview'] as String? ?? '') + 
                (item['webLink'] != null ? '\n\nLink: ${item['webLink']}' : ''),
            startsAt: dtStart,
            endsAt: dtEnd,
            allDay: isAllDay,
            location: item['location']?['displayName'] as String?,
            color: '#464EB8',
            eventType: 'event',
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> linkTeamsAccount() async {
    await _oauth.login();
  }
}
