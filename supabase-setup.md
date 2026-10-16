# إعداد تسجيل Nawa عبر Supabase

## 1. إعداد عناوين الموقع

في Supabase Dashboard افتح **Authentication → URL Configuration**، ثم ضع:

- Site URL: `https://alisadoonaskar.github.io/nawa-academy/`
- Redirect URL المسموح: `https://alisadoonaskar.github.io/nawa-academy/`

## 2. تفعيل تأكيد البريد

من **Authentication → Sign In / Providers → Email** فعّل تأكيد البريد الإلكتروني. لتسجيل المستخدمين العام، اضبط SMTP مخصصًا؛ خادم البريد التجريبي لدى Supabase لا يرسل إلى كل العناوين.

## 3. إنشاء صلاحية المسؤول

1. سجّل بنفسك من الموقع باستخدام `nawacompany19@gmail.com`.
2. افتح رسالة التأكيد وأكّد البريد، ثم سجّل الدخول.
3. من **SQL Editor** شغّل `supabase-setup.sql`.
4. بعد التأكد من ظهور المستخدم المؤكد في **Authentication → Users**، شغّل الاستعلام الأخير المعلّق في الملف لمنح هذا الحساب دور المسؤول.

لا تضع `service_role` أو أي مفتاح سري في الموقع أو GitHub. مفتاح النشر العام الموجود في الواجهة مصمم ليكون ظاهرًا، لكن صلاحيات الجداول يجب أن تبقى محمية بـ RLS. ولا توجد الآن جداول لمحتوى الدورات؛ هذا الإعداد يربط Auth ويضيف صلاحية مسؤول فقط.

