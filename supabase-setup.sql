-- Run this once in Supabase Dashboard > SQL Editor.
-- Creates a read-only role table. Only trusted SQL/dashboard administration
-- can assign or change roles; browser users cannot promote themselves.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table if not exists public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin'))
);

-- Course details are stored behind RLS so anonymous visitors can only see
-- public course cards; authenticated users can read lessons and resources.
create table if not exists public.course_content (
  course_id text primary key,
  content jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.course_content enable row level security;
revoke all on table public.course_content from anon, authenticated;
grant select, insert, update, delete on table public.course_content to authenticated;

drop policy if exists "authenticated users read course content" on public.course_content;
create policy "authenticated users read course content"
on public.course_content for select to authenticated using (true);

alter table public.user_roles enable row level security;
revoke all on table public.user_roles from anon, authenticated;
grant select on table public.user_roles to authenticated;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles r
    where r.user_id = (select auth.uid()) and r.role = 'admin'
  );
$$;

revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to authenticated;

drop policy if exists "admins insert course content" on public.course_content;
create policy "admins insert course content"
on public.course_content for insert to authenticated with check ((select private.is_admin()));

drop policy if exists "admins update course content" on public.course_content;
create policy "admins update course content"
on public.course_content for update to authenticated
using ((select private.is_admin())) with check ((select private.is_admin()));

drop policy if exists "admins delete course content" on public.course_content;
create policy "admins delete course content"
on public.course_content for delete to authenticated using ((select private.is_admin()));

drop policy if exists "read own role or admin roles" on public.user_roles;
create policy "read own role or admin roles"
on public.user_roles
for select
to authenticated
using (user_id = (select auth.uid()) or (select private.is_admin()));

-- Initial course material. Anonymous visitors cannot read this table.
insert into public.course_content (course_id, content) values
('c1', '{"lessons":["الموجة الكهرومغناطيسية والتردد","الطول الموجي والطيف الراديوي","التضمين: AM وFM وQAM","القدرة والكسب وفقد المسار"],"videos":[["مقدمة في الاتصالات اللاسلكية","https://www.youtube.com/results?search_query=wireless+communications+basics+university+lecture"],["شرح التضمين الرقمي","https://www.youtube.com/results?search_query=digital+modulation+QAM+educational"]],"report":"تقرير تعليمي: كيف تنتقل المعلومة لاسلكيًا؟ يشرح التردد والطول الموجي والتضمين، ويتضمن أسئلة مراجعة وتمرينًا لحساب الطول الموجي عند تردد معلوم.","project":"قارن بين Wi‑Fi وBluetooth وخلوي من حيث النطاق والتردد والاستخدام واستهلاك الطاقة."}'::jsonb),
('c2', '{"lessons":["مبادئ تطور الشبكات الخلوية","معمارية 5G NR وRAN","النواة المستقلة وغير المستقلة SA/NSA","تقطيع الشبكة وحالات الاستخدام"],"videos":[["Nokia Bell Labs: مقدمة 5G","https://www.nokia.com/networks/training/5g/bell-labs/associate-certification/"],["شرح شبكات 5G — مواد تعليمية","https://www.youtube.com/results?search_query=5G+network+architecture+educational+lecture"]],"report":"موجز تقني: طبقات شبكة 5G، الفرق بين RAN والنواة، وشرح مبسط لـ SA وNSA مع قاموس مصطلحات.","project":"ارسم مخططًا مبسطًا لاتصال هاتف بمحطة 5G ثم بالنواة وبالإنترنت."}'::jsonb),
('c3', '{"lessons":["رموز أجهزة الشبكة والوسائط","الطبقات المنطقية والفيزيائية","قراءة مخططات LAN","توثيق المخطط واكتشاف الأخطاء"],"videos":[["إنشاء أول شبكة في Packet Tracer","https://www.youtube.com/watch?v=fAmHNSz-G7Y"],["أساسيات مخططات الشبكات","https://www.youtube.com/results?search_query=how+to+read+network+diagrams+beginner"]],"report":"ورقة عمل: رموز الموجّهات والمحولات ونقاط الوصول والجدران النارية، مع مخطط شبكة مكتب صغير وأسئلة تحليل.","project":"صمّم شبكة لمختبر جامعي من 20 جهازًا، وبيّن الأجهزة والروابط وعناوين الشبكة."}'::jsonb),
('c4', '{"lessons":["ميزانية الوصلة ومكونات القدرة","فقد المسار والعوائق","مؤشرات RSSI وRSRP وSINR","مبادئ تخطيط وقياس التغطية"],"videos":[["RF Back to Basics — Keysight","https://connectlp.keysight.com/RFB2B_Fundamentals"],["أساسيات قياس الطيف الراديوي","https://www.youtube.com/results?search_query=RF+spectrum+analyzer+basics+Keysight"]],"report":"تقرير عملي: ميزانية وصلة لاسلكية تعليمية تتضمن قدرة الإرسال والكسب والخسائر، ومثالًا يشرح أثر المسافة والعوائق.","project":"قارن نظريًا بين موقعين لتركيب نقطة وصول، وحدد العوامل التي تؤثر في التغطية."}'::jsonb),
('c5', '{"lessons":["مكونات نظام إنترنت الأشياء","المستشعرات وجمع البيانات","MQTT وطرق الاتصال","عرض البيانات وتأمين الجهاز"],"videos":[["ما هو إنترنت الأشياء؟ — Arduino Education","https://www.youtube.com/watch?v=p4Pg2Ai5xfg"],["أنشطة Arduino Explore IoT Kit","https://www.youtube.com/watch?v=JquFx_QP53o"]],"report":"دليل مشروع مصغر: قياس درجة الحرارة وإرسال القراءة وعرضها، مع قائمة مكونات ومخطط تدفق واعتبارات خصوصية.","project":"اقترح نظام مراقبة بيئيًا لقاعات الجامعة، وحدد الحساس والاتصال والبيانات المطلوبة."}'::jsonb),
('c6', '{"lessons":["اختيار مشكلة قابلة للبحث","صياغة السؤال والأهداف","مراجعة المصادر والمنهجية","تحليل النتائج والتوثيق الأخلاقي"],"videos":[["دليل البحث الهندسي — جامعة McMaster","https://libguides.mcmaster.ca/eng"],["تطوير سؤال بحثي — IIT Library","https://guides.library.iit.edu/c.php?g=1480766&p=11035135"]],"report":"قالب إرشادي لمشروع التخرج: عنوان أولي، مشكلة البحث، الأهداف، مراجعة الأدبيات، المنهج، خطة العمل، النتائج المتوقعة، والمراجع. لا يتضمن بحثًا جاهزًا للتسليم.","project":"اكتب سؤالًا بحثيًا قابلًا للقياس في الاتصالات، وحدد طريقة جمع البيانات وكيفية توثيقها."}'::jsonb)
on conflict (course_id) do nothing;

-- After the owner has registered and confirmed their email, find their UUID
-- in Authentication > Users, then run this separately with that UUID:
-- insert into public.user_roles (user_id, role)
-- values ('PASTE-VERIFIED-OWNER-UUID-HERE', 'admin')
-- on conflict (user_id) do update set role = excluded.role;

