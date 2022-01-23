SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PlateProfileHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IssuedDate] [date] NULL,
	[ActivationDate] [date] NOT NULL,
	[DoNotRenewRegistration] [bit] NOT NULL,
	[ExpiryDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[LastModifiedDate] [datetimeoffset](7) NOT NULL,
	[LastModifiedReason] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PlateId] [bigint] NOT NULL,
	[UserId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PlateProfileHistories]  WITH CHECK ADD  CONSTRAINT [EPlate_PlateProfileHistories] FOREIGN KEY([PlateId])
REFERENCES [dbo].[Plates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PlateProfileHistories] CHECK CONSTRAINT [EPlate_PlateProfileHistories]
GO
ALTER TABLE [dbo].[PlateProfileHistories]  WITH CHECK ADD  CONSTRAINT [EPlateProfileHistory_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[PlateProfileHistories] CHECK CONSTRAINT [EPlateProfileHistory_User]
GO
