/*
 Copyright (©) 2003-2024 Teus Benschop.
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */


#include <public/notes.h>
#include <filter/roles.h>
#include <filter/string.h>
#include <filter/usfm.h>
#include <filter/text.h>
#include <filter/css.h>
#include <webserver/request.h>
#include <database/notes.h>
using namespace std;


string public_notes_url ()
{
  return "public/notes";
}


bool public_notes_acl (Webserver_Request& webserver_request)
{
  return Filter_Roles::access_control (webserver_request, Filter_Roles::guest ());
}


string public_notes (Webserver_Request& webserver_request)
{
  Database_Notes database_notes (webserver_request);

  
  const string bible = webserver_request.query ["bible"];
  const int book = filter::strings::convert_to_int (webserver_request.query ["book"]);
  const int chapter = filter::strings::convert_to_int (webserver_request.query ["chapter"]);
  
  
  const vector <int> identifiers = database_notes.select_notes ({bible}, book, chapter, 0, 1, 0, 0, "", "", "", false, -1, 0, "", -1);

  
  stringstream notesblock;
  for (const auto identifier : identifiers) {
    // Display only public notes.
    if (database_notes.get_public (identifier)) {
      notesblock << "<p class=" << quoted ("nowrap") << ">";
      string url_to_note = "note?id=" + filter::strings::convert_to_string (identifier);
      notesblock << "<a href=" << quoted (url_to_note) << ">";
      vector <Passage> passages = database_notes.get_passages (identifier);
      string verses;
      for (auto & passage : passages) {
        if (passage.m_book != book) continue;
        if (passage.m_chapter != chapter) continue;
        if (!verses.empty ()) verses.append (" ");
        verses.append (passage.m_verse);
      }
      notesblock << verses;
      notesblock << " | ";
      string summary = database_notes.get_summary (identifier);
      notesblock << summary;
      notesblock << "</a>";
      notesblock << "</p>";
    }
  }
  
  
  return notesblock.str();
}