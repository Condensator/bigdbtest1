SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditSNCHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsSNCCode] [bit] NOT NULL,
	[SNCRating] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[SNCRole] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[SNCAgent] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[SNCRatingDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditSNCHistories]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditSNCHistories] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditSNCHistories] CHECK CONSTRAINT [ECreditProfile_CreditSNCHistories]
GO
