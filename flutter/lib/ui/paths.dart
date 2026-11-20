import 'package:flutter/material.dart';

/// Route paths from 01-navigation.
class Paths {
  const Paths._();

  static const welcome = '/';
  static const signIn = '/sign-in';
  static const pin = '/pin';

  static const today = '/today';
  static const about = '/about';
  static const chat = '/chat';
  static const family = '/family';
  static const more = '/more';

  static const entryNew = '/entry/new';
  static const entry = '/entry/:id';
  static String entryOf(String id) => '/entry/$id';
  static const ask = 'ask';
  static String askFor(String id) => '$about/$ask?id=$id';
  static const works = '/works/:id';
  static String worksOf(String id) => '/works/$id';
  static const guide = '/guide';
  static const request = '/request';
  static const appointmentNew = '/appointment/new';
  static const appointment = '/appointment/:id';
  static String appointmentOf(String id) => '/appointment/$id';
  static const onboarding = '/onboarding';
  static const reportNew = '/report/new';
  static const report = '/report/:id';
  static String reportOf(String id) => '/report/$id';
}

/// Who may open a destination.
enum Reach { everyone, household }

/// The five bar destinations, in bar order.
enum Area {
  today(
    'Today',
    'Today',
    Icons.wb_sunny_outlined,
    Icons.wb_sunny,
    Paths.today,
    Reach.everyone,
  ),
  about(
    'About',
    'About Me',
    Icons.person_outline,
    Icons.person,
    Paths.about,
    Reach.everyone,
  ),
  chat(
    'Chat',
    'Chat',
    Icons.chat_bubble_outline,
    Icons.chat_bubble,
    Paths.chat,
    Reach.everyone,
  ),
  family(
    'Family',
    'Family',
    Icons.people_outline,
    Icons.people,
    Paths.family,
    Reach.household,
  ),
  more(
    'More',
    'More',
    Icons.more_horiz,
    Icons.more_horiz,
    Paths.more,
    Reach.everyone,
  );

  const Area(
    this.label,
    this.title,
    this.icon,
    this.activeIcon,
    this.path,
    this.reach,
  );

  final String label;
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final String path;
  final Reach reach;
}
