SELECT 
	duplicate AS match_id, 
	COUNT(duplicate) AS num_duplicates 
FROM duplicate 
GROUP BY duplicate