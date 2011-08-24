SELECT 
	match_id, 
	GROUP_CONCAT(COMMENT SEPARATOR  '|' ) AS correspondence
FROM comment_history
GROUP BY match_id
ORDER BY TIMESTAMP DESC 