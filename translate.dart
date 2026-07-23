import 'dart:io';

void main() {
  var file = File('lib/features/dashboard/presentation/new_home_screen_preview.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll("TextDirection.rtl", "widget.isArabic ? TextDirection.rtl : TextDirection.ltr");
  content = content.replaceAll("'الإشعارات'", "widget.isArabic ? 'الإشعارات' : 'Alerts'");
  content = content.replaceAll("'الأصدقاء'", "widget.isArabic ? 'الأصدقاء' : 'Friends'");
  content = content.replaceAll("'بلوت'", "widget.isArabic ? 'بلوت' : 'Baloot'");
  content = content.replaceAll("'المزيد'", "widget.isArabic ? 'المزيد' : 'More'");
  content = content.replaceAll("'غير مشترك'", "widget.isArabic ? 'غير مشترك' : 'Free Tier'");
  content = content.replaceAll("'1,240 متصل'", "widget.isArabic ? '1,240 متصل' : '1,240 Online'");
  content = content.replaceAll("'اربح'", "widget.isArabic ? 'اربح' : 'Win'");
  content = content.replaceAll("'جديد'", "widget.isArabic ? 'جديد' : 'New'");
  content = content.replaceAll("'\$count انتصارات'", "widget.isArabic ? '\$count انتصارات' : '\$count Wins'");
  content = content.replaceAll("'👑 احصل على VIP الآن'", "widget.isArabic ? '👑 احصل على VIP الآن' : '👑 Get VIP Now'");
  content = content.replaceAll("'جلسة صوتية'", "widget.isArabic ? 'جلسة صوتية' : 'Voice Room'");
  content = content.replaceAll("'إنشاء جلسة'", "widget.isArabic ? 'إنشاء جلسة' : 'Create Room'");
  content = content.replaceAll("'لعبة ودية'", "widget.isArabic ? 'لعبة ودية' : 'Friendly Match'");
  content = content.replaceAll("'قائمة الجلسات'", "widget.isArabic ? 'قائمة الجلسات' : 'Room List'");
  content = content.replaceAll("'العب بلوت'", "widget.isArabic ? 'العب بلوت' : 'Play Baloot'");
  content = content.replaceAll("'جاري البحث'", "widget.isArabic ? 'جاري البحث' : 'Searching'");
  content = content.replaceAll("'كأس بلوت'", "widget.isArabic ? 'كأس بلوت' : 'Baloot Cup'");
  content = content.replaceAll("'كأس كملنا'", "widget.isArabic ? 'كأس كملنا' : 'Kammelna Cup'");
  content = content.replaceAll("'انضم إلى البطولة الكبرى الآن'", "widget.isArabic ? 'انضم إلى البطولة الكبرى الآن' : 'Join the grand tournament now'");
  content = content.replaceAll("'▶ العب'", "widget.isArabic ? '▶ العب' : '▶ Play'");
  content = content.replaceAll("lbl: 'المتجر'", "lbl: widget.isArabic ? 'المتجر' : 'Store'");
  content = content.replaceAll("lbl: 'المجتمع'", "lbl: widget.isArabic ? 'المجتمع' : 'Community'");
  content = content.replaceAll("lbl: 'الرئيسية'", "lbl: widget.isArabic ? 'الرئيسية' : 'Home'");
  content = content.replaceAll("lbl: 'الدوريات'", "lbl: widget.isArabic ? 'الدوريات' : 'Tournaments'");
  content = content.replaceAll("lbl: 'دردشة'", "lbl: widget.isArabic ? 'دردشة' : 'Chat'");

  // Fix rank string translations (they are inside switch cases)
  content = content.replaceAll("'خبير'", "widget.isArabic ? 'خبير' : 'Expert'");
  content = content.replaceAll("'محترف'", "widget.isArabic ? 'محترف' : 'Pro'");
  content = content.replaceAll("'أسطورة'", "widget.isArabic ? 'أسطورة' : 'Legend'");
  
  file.writeAsStringSync(content);
  print('Done new_home');
}
