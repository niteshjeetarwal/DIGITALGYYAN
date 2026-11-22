DIGITALGYYAN Dynamic CMS — first implementation package

WHAT'S INCLUDED
- Updated admin.html with:
  - Dynamic Website Structure manager
  - Create unlimited-depth Section/Class/Subject/Part/Chapter/Folder/Category nodes
  - Set icon, accent color and display order
  - Rename/edit structure items
  - Delete empty leaf nodes (children must be moved/deleted first)
  - Link an uploaded resource to a structure node
  - Rename a resource's display title
  - Move a resource to another structure node
  - Multiple-file upload remains enabled
- CMS-MIGRATION.sql adds the dynamic structure table and nullable node_id on resources.
- Existing website files and Supabase configuration are retained in the ZIP.

IMPORTANT SETUP
1. Keep a backup of the current site and Supabase database.
2. In Supabase SQL Editor, run CMS-MIGRATION.sql AFTER SUPABASE-SETUP.sql has already been run.
3. Keep admin-config.js as your own configured file. Never share its secret keys; only the publishable/anon key belongs in client-side config.
4. Deploy the updated folder to Netlify only after testing in a separate deploy/preview.
5. Log into Admin Panel and create a test Section, then a Chapter and Folder. Upload one small test file and assign it to a node.
6. Test rename/move/publish/delete carefully before uploading real content.

LIMITATIONS IN THIS ITERATION
- Existing legacy Section / Subject / Category dropdowns remain for backward compatibility.
- New structure items are managed in the Admin Panel and can be assigned to resource records, but the existing public Study Resources page and homepage do not yet automatically render the full nested folder tree as navigable pages/cards. That frontend synchronization is a separate integration step and should be completed/tested before treating this as a fully dynamic website builder.
- Copy, bulk move, full folder move, undo/restore, and audit history are planned but are not fully implemented in this package.
- Actual stored object filename is not renamed; Rename changes the display title, avoiding broken storage URLs.
- Supabase plan limits apply; configured file size is not the same as the actual plan's permitted maximum.
