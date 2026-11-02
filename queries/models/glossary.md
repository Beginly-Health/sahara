# Metabase glossary

Paste each term into Metabase's glossary. Keep this file and Metabase in step.

| Term | Definition |
| --- | --- |
| Candidate | A person registered on Beginly who is not staff or a recruiter. Includes deleted accounts and people still in onboarding. Use the Candidates model. |
| Super Admin | Beginly platform staff, marked by `users.adminsales = true`. They never count as candidates or employer members, in any report. The Models already leave them out. |
| Total Candidates | Everyone ever registered as a candidate, including deleted accounts. Count all rows in the Candidates model. |
| Active Candidate | A candidate whose account isn't deleted. Use `is_active` in the Candidates model. |
| Active Candidate Seeking Jobs | An active candidate with job seeking turned on. Use `is_seeking_jobs` in the Candidates model. |
| Onboarded | A candidate who finished onboarding. Use `finished_onboarding` in the Candidates model, only when the question asks for it. |
| Employer | A hospital or group hiring on Beginly. Use the Employers model. |
| Active Employer | An employer that isn't deleted. Use `is_active` in the Employers model. |
| Job | A position posted by an employer, also called an opportunity. Use the Opportunities model. |
| Live Job | A job candidates can see today: published, past its publish date, not deleted and not closed. Use `is_live` in the Opportunities model. |
| Match | A pairing of a candidate and an opportunity. Use the Matches model. |
| Accepted Match | A match the candidate accepted. Use `is_accepted` in the Matches model. |
| Interested Candidate | An accepted match the employer hasn't declined or withdrawn. Carcross's Interested tile shows these, limited to candidates seeking jobs. Use `is_interested` in the Matches model. |
| Saved Match | A match the candidate saved. Use `is_saved` in the Matches model. |
| Declined Match | A match the candidate declined. Use `is_declined` in the Matches model. |
| Engagement | A candidate accepting, saving or declining a match. Use `is_engaged` in the Matches model. |
